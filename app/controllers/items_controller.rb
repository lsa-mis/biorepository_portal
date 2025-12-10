require 'csv'
class ItemsController < ApplicationController
  include ActiveFiltersHelper
  skip_before_action :authenticate_user!, only: [ :show, :search, :quick_search, :export_to_csv ]
  before_action :set_item, only: [ :show ]

  # GET /items/1 or /items/1.json
  def show
    @identifications = @item.identifications.order(current: :desc)
    @preparations = @item.preparations
    @collections = Collection.all
  end

  def quick_search
    session[:quick_search_q] = params[:q]
    redirect_to search_items_path
  end

  def search
    Rails.logger.info "++++++++++++++++++++++++++++++ In ItemsController#search"

    @view = params[:switch_view]&.in?(['rows', 'cards']) ? params[:switch_view] : 'rows'

    collection_ids = extract_collection_ids
    
    # Add timeout protection for filter data
    Timeout::timeout(10) do
      setup_filter_data(collection_ids)
    end
    
    setup_search_query
    execute_search_and_paginate

    Rails.logger.info "========================= hell"
    
    respond_to do |format|
      format.html { render :search_result }
    end
    rescue Timeout::Error
      Rails.logger.error "Search timeout - filter data took too long"
      respond_to do |format|
        format.html { render plain: "Search is taking too long. Please try with fewer filters.", status: 408 }
        format.json { render json: { error: "Search is taking too long. Please try with fewer filters." }, status: 408 }
      end
    rescue => e
      Rails.logger.error "Search error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      respond_to do |format|
        format.html { render plain: "An error occurred during search", status: 500 }
        format.json { render json: { error: "An error occurred during search" }, status: 500 }
      end
    end

  include ActionController::Live

  def export_to_csv
    transform_search_groupings
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=items-#{Date.today}.csv"
    response.headers['Last-Modified'] = Time.now.httpdate
    begin
      csv = CSV.new(response.stream)
      csv << TITLEIZED_HEADERS
      items = if params[:q].present?
        @q = Item.ransack(params[:q])
        @q.result
      else
        Item.all
      end
      items.in_batches(of: 1000) do |batch|
        batch = batch.includes(:collection, :current_identification, :preparations)
        batch.each do |item|
          row = []
          ITEM_FIELDS.each do |key|
            if key == "collection_id"
              row << sanitize_csv_value(item.collection.division)
            else
              row << sanitize_csv_value(item.attributes[key])
            end
          end

          identification = item.current_identification
          if identification
            IDENTIFICATIONS_FIELDS.each do |id_key|
              row << sanitize_csv_value(identification.attributes[id_key])
            end
          else
            IDENTIFICATIONS_FIELDS.each do |id_key|
              row << sanitize_csv_value(nil)
            end
          end
          item.preparations.each do |prep|
            csv << generate_row_with_preparation(row, prep)
          end
        end
      end
    ensure
      response.stream.close
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.require(:item).permit(:occurrence_id, :catalog_number, :modified, :recorded_by, 
        :individual_count, :sex, :life_stage, :reproductive_condition, :vitality, 
        :other_catalog_numbers, :occurrence_remarks, :organism_remarks, :associated_sequences, 
        :field_number, :event_date_start, :event_date_end, :verbatim_event_date, :sampling_protocol, 
        :event_remarks, :continent, :country, :state_province, :county, :locality, :verbatim_locality, 
        :verbatim_elevation, :minimum_elevation_in_meters, :maximum_elevation_in_meters, :decimal_latitude, 
        :decimal_longitude, :coordinate_uncertainty_in_meters, :verbatim_coordinates, :georeferenced_by, 
        :georeferenced_date, :geodetic_datum, :georeference_protocol, :archived, :collection_id)
    end

    def transform_quick_search_params
      @quick_search_param = extract_quick_search_param
      return unless @quick_search_param.present?
      construct_search_params(@quick_search_param)
      add_country_and_state_filters(@quick_search_param)
    end

    def extract_quick_search_param
      return unless session[:quick_search_q].is_a?(Hash)
      session[:quick_search_q]["country_case_insensitive_or_state_province_case_insensitive_or_identifications_scientific_name_or_identifications_vernacular_name_cont"]
    end

    def construct_search_params(quick_search_param)
      params[:q] = ActionController::Parameters.new({
        groupings: {
          "0" => {
            "identifications_scientific_name_i_cont_any" => [quick_search_param],
            "identifications_vernacular_name_i_cont_any" => [quick_search_param],
            "m" => "or"
          }
        }
      }).permit!
    end

    def add_country_and_state_filters(quick_search_param)
      if @countries.flatten.include?(quick_search_param.downcase)
        params[:q]["country_case_insensitive_in"] = [quick_search_param.downcase]
      end
      if @states.flatten.include?(quick_search_param.downcase)
        params[:q]["state_province_case_insensitive_in"] = [quick_search_param.downcase]
      end
    end

    def transform_search_groupings
      if params[:q] && params[:q][:groupings]
        transformed_groupings = {}
        params[:q][:groupings].each do |group_index, group_data|
          group = {}
          group_data.each do |field_index, field_data|
            
            next if field_index == "m"
            next if field_data.class == Array
            next unless field_data["field"].present? && field_data["value"].present?

            field = field_data["field"]
            value = field_data["value"]

            group[field] ||= []
            group[field] << value
          end

          # Wrap group in an indexed key
          transformed_groupings[group_index] = group
          # Add matcher if present
          transformed_groupings[group_index]["m"] = group_data["m"].presence || "or"
        end
        params[:q][:groupings] = ActionController::Parameters.new(transformed_groupings).permit!
      end
    end

    def generate_row_with_preparation(row, prep)
      row_with_prep = row.dup
      PREPARATIONS_FIELDS.each do |prep_key|
        row_with_prep << sanitize_csv_value(prep.attributes[prep_key])
      end
      row_with_prep
    end

    def extract_collection_ids
      if params[:q]&.dig(:collection_id_in).present?
        params[:q][:collection_id_in]
      elsif params[:collection_id].present?
        collection_ids = [params[:collection_id].to_i]
        params[:q] = ActionController::Parameters.new("collection_id_in" => [collection_ids.first])
        collection_ids
      else
        Collection.pluck(:id)
      end
    end

    def setup_filter_data(collection_ids)

      cache_key = "filters_#{collection_ids.sort.join('_')}"
      filter_data = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        build_filter_data(collection_ids)
      end
      
      @continents, @countries, @states, @sexs = filter_data[:geo]
      @kingdoms, @phylums, @classes, @orders, @families, @genuses = filter_data[:taxonomy]
      @prep_types = filter_data[:prep_types]
    end

    def build_filter_data(collection_ids)
      # Single query to get all needed data
      items_data = Item.where(collection_id: collection_ids)
                      .left_joins(:current_identification, :preparations)
                      .pluck(:continent, :country, :state_province, :sex,
                            'identifications.kingdom', 'identifications.phylum', 'identifications.class_name',
                            'identifications.order_name', 'identifications.family', 'identifications.genus',
                            'preparations.prep_type')
      
      geo_sets = Array.new(4) { Set.new }
      taxonomy_sets = Array.new(6) { Set.new }
      prep_types_set = Set.new
      
      items_data.each do |continent, country, state_province, sex, kingdom, phylum, class_name, order_name, family, genus, prep_type|
        # Geographic data
        geo_sets[0].add([continent&.titleize, continent&.downcase]) if continent.present?
        geo_sets[1].add([country&.titleize, country&.downcase]) if country.present?
        geo_sets[2].add([state_province&.titleize, state_province&.downcase]) if state_province.present?
        geo_sets[3].add([sex&.titleize, sex&.downcase]) if sex.present?
        
        # Taxonomy data
        taxonomy_sets[0].add([kingdom&.titleize, kingdom&.downcase]) if kingdom.present?
        taxonomy_sets[1].add([phylum&.titleize, phylum&.downcase]) if phylum.present?
        taxonomy_sets[2].add([class_name&.titleize, class_name&.downcase]) if class_name.present?
        taxonomy_sets[3].add([order_name&.titleize, order_name&.downcase]) if order_name.present?
        taxonomy_sets[4].add([family&.titleize, family&.downcase]) if family.present?
        taxonomy_sets[5].add([genus&.titleize, genus&.downcase]) if genus.present?
        
        # Prep types
        prep_types_set.add([prep_type&.titleize, prep_type&.downcase]) if prep_type.present?
      end
      
      {
        geo: geo_sets.map { |set| set.sort_by(&:first) },
        taxonomy: taxonomy_sets.map { |set| set.sort_by(&:first) },
        prep_types: prep_types_set.sort_by(&:first)
      }
    end

    def setup_search_query
      @sort = sanitize_sort_parameter(params[:sort])
      
      if session[:quick_search_q].present?
        @q = Item.ransack(session[:quick_search_q])
        transform_quick_search_params
        session.delete(:quick_search_q)
        @quick_search_filters = true
      else
        transform_search_groupings unless params[:page].present?
        @quick_search_filters = false
        
        @q = Item.left_outer_joins(:current_identification, :collection)
                .select('items.*, identifications.scientific_name, collections.division')
                .order(@sort)
                .ransack(params[:q])
      end
    end
    
    # Sanitize sort parameters to prevent SQL injection
    def sanitize_sort_parameter(sort_param)
      # Get whitelisted sort options from helper
      allowed_sorts = ApplicationController.helpers.fields_to_sort_items
                                                  .map(&:second)
                                                  .compact
                                                  .to_set
      
      # Default fallback
      default_sort = 'items.catalog_number asc'
      
      # Return default if no sort provided
      return default_sort if sort_param.blank?
      
      # Check if provided sort is in whitelist
      if allowed_sorts.include?(sort_param.strip)
        sort_param.strip
      else
        # Log potential security attempt
        Rails.logger.warn "Invalid sort parameter attempted: #{sort_param}"
        default_sort
      end
    end

    def execute_search_and_paginate
      # Get base results
      filtered_items = @q.result.distinct
      
      # Count only distinct item IDs to avoid PostgreSQL error
      @total_items = @q.result.distinct.count('items.id')
      collection_ids = @q.result.distinct.reorder('').pluck('items.collection_id')
      @collections = Collection.where(id: collection_ids).pluck(:division).uniq.join(', ')
      
      # Paginated items with includes for efficiency
      @items = filtered_items.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)

      @all_collections = Collection.order(:division)
      setup_dynamic_fields
    end
    
    def setup_dynamic_fields
      @dynamic_fields = []
      return unless params.dig(:q, :groupings).present?
      
      params.dig(:q, :groupings).each do |group_num, values|
        group_pairs = []
        values.each do |field, val|
          
          next if field == "m" || val.blank?
          group_pairs << { field: field, value: val }
        end
        @dynamic_fields << group_pairs unless group_pairs.empty?
      end
      @active_filters = format_active_filters(dynamic_fields: @dynamic_fields)
    end

end

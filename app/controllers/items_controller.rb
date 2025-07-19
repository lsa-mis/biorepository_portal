require 'csv'
class ItemsController < ApplicationController
  include ActiveFiltersHelper
  skip_before_action :authenticate_user!, only: [ :show, :search ]
  before_action :set_item, only: [ :show ]

  # GET /items or /items.json
  def index
    @items = Item.all
  end

  # GET /items/1 or /items/1.json
  def show
    @identifications = @item.identifications.order(current: :desc)
    @preparations = @item.preparations
    @collections = Collection.all
  end

  def quick_search
    @q = Item.ransack(params[:q])
    session[:quick_search_q] = params[:q]
    redirect_to search_items_path
  end

  def search
    if params[:switch_view] == 'rows'
      @view = 'rows'
    elsif params[:switch_view] == 'cards'
      @view = 'cards'
    else
      @view = @view.present? ? @view : 'rows'
    end

    if params[:q]&.dig(:collection_id_in).present?
      collection_ids = params[:q][:collection_id_in]
    elsif params[:collection_id].present?
      collection_ids = [params[:collection_id].to_i]
      params[:q] = ActionController::Parameters.new("collection_id_in" => [collection_ids.first])
    else
      collection_ids = Collection.all.pluck(:id)
    end

    included_items = Item.where(collection: collection_ids)

    @continents, @countries, @states, @sexs =
      Rails.cache.fetch("geo_filters_#{collection_ids.sort.join('_')}", expires_in: 12.hours) do
        plucked_items = included_items.pluck(:continent, :country, :state_province, :sex)
        continents, countries, states, sexs = Array.new(4) { Set.new }

        plucked_items.each do |continent, country, state_province, sex|
          continents.add([continent&.titleize, continent&.downcase]) if continent.present?
          countries.add([country&.titleize, country&.downcase]) if country.present?
          states.add([state_province&.titleize, state_province&.downcase]) if state_province.present?
          sexs.add([sex&.titleize, sex&.downcase]) if sex.present?
        end

        [continents, countries, states, sexs].map { |set| set.sort_by(&:first) }
      end

    @kingdoms, @phylums, @classes, @orders, @families, @genuses = 
      Rails.cache.fetch("taxonomy_filters_#{collection_ids.sort.join('_')}", expires_in: 12.hours) do
        taxonomies = included_items.joins(:current_identification)
          .pluck('identifications.kingdom', 'identifications.phylum', 'identifications.class_name', 
                 'identifications.order_name', 'identifications.family', 'identifications.genus')

        kingdoms, phylums, classes, orders, families, genuses = Array.new(6) { Set.new }

        taxonomies.each do |kingdom, phylum, class_name, order_name, family, genus|
          kingdoms.add([kingdom&.titleize, kingdom&.downcase]) if kingdom.present?
          phylums.add([phylum&.titleize, phylum&.downcase]) if phylum.present?
          classes.add([class_name&.titleize, class_name&.downcase]) if class_name.present?
          orders.add([order_name&.titleize, order_name&.downcase]) if order_name.present?
          families.add([family&.titleize, family&.downcase]) if family.present?
          genuses.add([genus&.titleize, genus&.downcase]) if genus.present?
        end

        [kingdoms, phylums, classes, orders, families, genuses].map do |set|
          set.sort_by(&:first)
        end
      end

    if session[:quick_search_q].present?
      @q = Item.ransack(session[:quick_search_q])
      transform_quick_search_params
      @message = "Quick search results for: Scientific Name or Vernacular Name or Country or State/Province LIKE '#{extract_quick_search_param}'"
      session.delete(:quick_search_q)
    else
      transform_search_groupings
      @q = Item.includes(:collection, :identifications, :preparations).ransack(params[:q])
    end

    filtered_items = @q.result
    @items = filtered_items.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    @collections = Item.joins(:collection).where(id: filtered_items.select(:id)).distinct.pluck('collections.division').join(', ')
    @all_collections = Collection.all
    
    @dynamic_fields = []
    # Reprocessing params to ensure dynamic fields are included
    if params.dig(:q, :groupings).present?
      params.dig(:q, :groupings).each do |group_num, values|
        group_pairs = []
        values.each do |field, val|
          next if field == "m" || val.blank?
          group_pairs << { field: field, value: val }
        end
        @dynamic_fields << group_pairs unless group_pairs.empty?
        
      end
    end
    
    @active_filters = format_active_filters(dynamic_fields: @dynamic_fields)

    respond_to do |format|
      format.html { render :search_result }
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
      if params[:q] && params[:q][:groupings] && params[:q][:groupings]["0"]["0"].present?
        transformed_groupings = {}
        params[:q][:groupings].each do |group_index, group_data|
          group = {}
          group_data.each do |field_index, field_data|
            next if field_index == "m"
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
end

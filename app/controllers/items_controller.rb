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
    @max_number_of_preparations = fetch_max_number_of_preparations(@item.collection.id)
    @preparations = @item.preparations
    @collections = Collection.all
  end

  def search

    if params[:switch_view] == 'rows'
      @view = 'rows'
    elsif params[:switch_view] == 'cards'
      @view = 'cards'
    else
      @view = @view.present? ? @view : 'rows'
    end

    transform_search_groupings

    if params[:q]&.dig(:collection_id_in).present?
      collection_ids = params[:q][:collection_id_in]
    else
      collection_ids = Collection.all.pluck(:id)
    end

    @continents = Item.where(collection: collection_ids).pluck(:continent)
      .compact.reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @countries = Item.where(collection: collection_ids).pluck(:country)
      .compact
      .reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @states = Item.where(collection: collection_ids).pluck(:state_province)
        .compact.reject(&:blank?)
        .map { |s| [s.titleize, s.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }

    @sexs = Item.where(collection: collection_ids).pluck(:sex)
      .compact.reject(&:blank?)
      .map { |s| [s.titleize, s.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }

    @kingdoms = Rails.cache.fetch('kingdoms', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.kingdom')
        .compact.reject(&:blank?)
        .map { |k| [k.titleize, k.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @phylums = Rails.cache.fetch('phylums', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.phylum')
        .compact.reject(&:blank?)
        .map { |p| [p.titleize, p.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    end

    @classes = Rails.cache.fetch('classes', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.class_name')
        .compact.reject(&:blank?)
        .map { |c| [c.titleize, c.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @orders = Rails.cache.fetch('orders', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.order_name')
        .compact.reject(&:blank?)
        .map { |o| [o.titleize, o.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    end

    @families = Rails.cache.fetch('families', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.family')
        .compact.reject(&:blank?)
        .map { |f| [f.titleize, f.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @genuses = Rails.cache.fetch('genuses', expires_in: 12.hours) do
      Item.where(collection: collection_ids).joins(:current_identification)
        .pluck('identifications.genus')
        .compact.reject(&:blank?)
        .map { |g| [g.titleize, g.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @q = Item.includes(:collection, :identifications, :preparations).ransack(params[:q])
    @items = @q.result.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    @collections = Item.joins(:collection).where(id: @q.result.select(:id))
                        .distinct.pluck('collections.division').join(', ')
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
      format.turbo_stream
      format.html { render :search_result }
    end
    
  end

  def export_to_csv
    transform_search_groupings
    if params[:format] == 'csv'
      if params[:q].present? 
        @q = Item.includes(:collection, preparations: :requestables).ransack(params[:q])
        items = @q.result
      else
        items = Item.all
      end
      data = data_to_csv(items)
    end

    respond_to do |format|
      format.csv { send_data data, filename: "items-#{Date.today}.csv"}
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

    def search_params
      params.permit(:q)
    end

    def transform_search_groupings
      if params[:q] && params[:q][:groupings] && !params[:page].present?
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

    ITEM_FIELDS = %w[
      occurrence_id associated_sequences catalog_number collection_id continent_case_insensitive coordinate_uncertainty_in_meters
      country_case_insensitive county created_at decimal_latitude decimal_longitude event_date_end event_date_start event_remarks
      field_number geodetic_datum georeference_protocol georeferenced_by georeferenced_date id individual_count
      life_stage locality maximum_elevation_in_meters minimum_elevation_in_meters modified
      occurrence_remarks organism_remarks other_catalog_numbers recorded_by reproductive_condition sampling_protocol
      sex_case_insensitive state_province_case_insensitive updated_at verbatim_coordinates verbatim_elevation verbatim_event_date verbatim_locality vitality
    ]

    PREPARATIONS_FIELDS = %w[prep_type description]
    IDENTIFICATIONS_FIELDS = %w[scientific_name vernacular_name class_name order_name family genus]
    HEADERS = ITEM_FIELDS + IDENTIFICATIONS_FIELDS + PREPARATIONS_FIELDS
    TITLEIZED_HEADERS = HEADERS.map { |h|
      case h
      when 'class_name' then 'Class'
      when 'order_name' then 'Order'
      else h.to_s.titleize
      end
    }

    def data_to_csv(items = Item.all)
      CSV.generate(headers: true) do |csv|
        csv << TITLEIZED_HEADERS
        items.each do |item|
          row = []
          ITEM_FIELDS.each do |key|
            if key == "collection_id"
              row << item.collection.division
            else
              row << item.attributes[key]
            end
          end
          item.identifications.each do |identification|
            if identification.current
              IDENTIFICATIONS_FIELDS.each do |id_key|
                row << identification.attributes[id_key]
              end
              break
            end
          end
          item.preparations.each do |prep|
            row_with_prep = row.dup
            PREPARATIONS_FIELDS.each do |prep_key|
              row_with_prep << prep.attributes[prep_key]
            end
            csv << row_with_prep 
          end
        end
      end
    end
end

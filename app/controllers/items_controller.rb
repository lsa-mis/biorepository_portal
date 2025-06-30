class ItemsController < ApplicationController
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
    if params[:q] && params[:q][:dynamic_fields]
      params[:q][:dynamic_fields].each do |field_hash|
        next if field_hash.blank? || !field_hash.is_a?(Hash)
        field = field_hash["field"]
        value = field_hash["value"]
        next if field.blank? || value.blank?

        params[:q][field] = value
      end
    end
    @q = Item.ransack(params[:q])
    @items = @q.result.page(params[:page]).per(15)
    @collections =  @items.map { |i| i.collection.division}.uniq.join(', ')
    @all_collections = Collection.all
    @countries = Item.distinct.pluck(:country)
      .compact
      .reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @states = Item.distinct.pluck(:state_province)
      .compact.reject(&:blank?)
      .map { |s| [s.titleize, s.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @sexs = Item.distinct.pluck(:sex)
      .compact.reject(&:blank?)
      .map { |s| [s.titleize, s.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @continents = Item.distinct.pluck(:continent)
      .compact.reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }

    # Build human-readable active filters list
    @active_filters = []

      # Map fields to labels (you can expand this map)
    field_labels = {
      "collection_id_in" => "Collection",
      "country_case_insensitive_in" => "Country",
      "state_province_case_insensitive_in" => "State / Province",
      "sex_case_insensitive_in" => "Sex",
      "continent_case_insensitive_in" => "Continent"
    }

    params[:q]&.each do |key, value|
      next if value.blank? || key == "dynamic_fields"
      if field_labels[key]
        if value.is_a?(Array)
          labels = value.map(&:titleize).join(', ')
          @active_filters << "#{field_labels[key]}: #{labels}"
        else
          @active_filters << "#{field_labels[key]}: #{value.titleize}"
        end
      elsif key.match?(/_i_cont|_eq|_gteq|_lteq/)
        label = key.humanize.gsub(/_i_cont|_eq|_gteq|_lteq/, '').titleize
        @active_filters << "#{label}: #{value}"
      end
    end

    # Dynamic fields
    if params[:q].present? && params[:q][:dynamic_fields].is_a?(Array)
      params[:q][:dynamic_fields].each do |field_hash|
        field = field_hash["field"]
        value = field_hash["value"]
        next if field.blank? || value.blank?
        label = field.humanize.gsub(/_i_cont|_eq|_gteq|_lteq/, '').titleize
        @active_filters << "#{label}: #{value}"
      end
    end

    render :search_result
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params.expect(:id))
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
end

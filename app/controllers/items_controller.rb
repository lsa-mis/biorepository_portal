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
    if params[:q] && params[:q][:dynamic_fields]
      params[:q][:dynamic_fields].each do |_, group|
        group.each do |_, field_hash|
          next if field_hash["field"].blank? || field_hash["value"].blank?
          params[:q][field_hash["field"]] = field_hash["value"]
        end
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

    
    @active_filters = format_active_filters(params)
    respond_to do |format|
      format.turbo_stream
      format.html { render :search_result }
    end
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

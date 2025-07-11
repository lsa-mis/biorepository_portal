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
    @continents = Item.pluck(:continent)
      .compact.reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @countries = Item.pluck(:country)
      .compact
      .reject(&:blank?)
      .map { |c| [c.titleize, c.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    @states = Item.pluck(:state_province)
        .compact.reject(&:blank?)
        .map { |s| [s.titleize, s.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }

    @sexs = Item.pluck(:sex)
      .compact.reject(&:blank?)
      .map { |s| [s.titleize, s.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }

    @kingdoms = Rails.cache.fetch('kingdoms', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.kingdom')
        .compact.reject(&:blank?)
        .map { |k| [k.titleize, k.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @phylums = Rails.cache.fetch('phylums', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.phylum')
        .compact.reject(&:blank?)
        .map { |p| [p.titleize, p.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    end

    @classes = Rails.cache.fetch('classes', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.class_name')
        .compact.reject(&:blank?)
        .map { |c| [c.titleize, c.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @orders = Rails.cache.fetch('orders', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.order_name')
        .compact.reject(&:blank?)
        .map { |o| [o.titleize, o.downcase] }
      .uniq
      .sort_by { |pair| pair[0] }
    end

    @families = Rails.cache.fetch('families', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.family')
        .compact.reject(&:blank?)
        .map { |f| [f.titleize, f.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @genuses = Rails.cache.fetch('genuses', expires_in: 12.hours) do
      Item.joins(:current_identification)
        .pluck('identifications.genus')
        .compact.reject(&:blank?)
        .map { |g| [g.titleize, g.downcase] }
        .uniq
        .sort_by { |pair| pair[0] }
    end

    @q = Item.includes(:collection, preparations: :requestables).ransack(params[:q])
    @items = @q.result.page(params[:page]).per(15)
    @collections =  @items.map { |i| i.collection.division}.uniq.join(', ')
    @all_collections = Collection.all

    @dynamic_fields = []
    # Reprocessing params to ensure dynamic fields are included
    if params.dig(:q, :groupings).present?
      params.dig(:q, :groupings).each do |group_num, values|
        group_pairs = []
        values.each do |field_num, input_hash|
          next if input_hash["field"] == "m"
          next if input_hash["value"].blank?
          group_pairs << { field: input_hash[:field], value: input_hash[:value] }
        end
        @dynamic_fields << group_pairs unless group_pairs.empty?
      end
    end
    
    @active_filters = format_active_filters(params)
    respond_to do |format|
      format.turbo_stream
      format.html { render :search_result }
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
end

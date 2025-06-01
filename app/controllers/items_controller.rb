class ItemsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_item, only: %i[ show ]

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

  def search
    @q = Item.ransack(params[:q])
    @items = @q.result.page(params[:page]).per(15)
    render :search_result
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.expect(item: [ :occurrence_id, :catalog_number, :modified, :recorded_by, :individual_count, :sex, :life_stage, :reproductive_condition, :vitality, :other_catalog_numbers, :occurrence_remarks, :organism_remarks, :associated_sequences, :field_number, :event_date_start, :event_date_end, :verbatim_event_date, :sampling_protocol, :event_remarks, :continent, :country, :state_province, :county, :locality, :verbatim_locality, :verbatim_elevation, :minimum_elevation_in_meters, :maximum_elevation_in_meters, :decimal_latitude, :decimal_longitude, :coordinate_uncertainty_in_meters, :verbatim_coordinates, :georeferenced_by, :georeferenced_date, :geodetic_datum, :georeference_protocol, :archived, :collection_id ])
    end
end

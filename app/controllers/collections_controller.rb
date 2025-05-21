class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[ show edit update destroy ]

  # GET /collections or /collections.json
  def index
    @collections = Collection.all
    authorize @collections
  end

  # GET /collections/1 or /collections/1.json
  def show
    @items = @collection.items.page(params[:page]).per(15)
  end

  # GET /collections/new
  def new
    @collection = Collection.new
    authorize @collection
  end

  # GET /collections/1/edit
  def edit
  end

  # POST /collections or /collections.json
  def create
    @collection = Collection.new(collection_params)

    respond_to do |format|
      if @collection.save
        format.html { redirect_to @collection, notice: "Collection was successfully created." }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1 or /collections/1.json
  def update
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { redirect_to @collection, notice: "Collection was successfully updated." }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1 or /collections/1.json
  def destroy
    @collection.destroy!

    respond_to do |format|
      format.html { redirect_to collections_path, status: :see_other, notice: "Collection was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
    collection_id = params[:collection_id]
    return redirect_to request.referer, notice: 'No file added' if params[:file].nil?
    return redirect_to request.referer, notice: 'Only CSV files allowed' unless params[:file].content_type == 'text/csv'

    files = Array(params[:file])
    files.each do |file|
      CsvImportService.new(file, collection_id).call
    end

    redirect_to request.referer, notice: 'Import started...'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = Collection.find(params.expect(:id))
      authorize @collection
    end

    # Only allow a list of trusted parameters through.
    def collection_params
      params.expect(collection: [ :division, :admin_group, :description, :division_page_url, :link_to_policies, :image ])
    end
end

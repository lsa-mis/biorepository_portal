class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[ show edit update destroy search ]
  skip_before_action :authenticate_user!, only: [ :index, :show, :add_item_to_checkout ]

  # GET /collections or /collections.json
  def index
    @collections = Collection.all
  end

  # GET /collections/1 or /collections/1.json
  def show
    @q1 = @collection.items.ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per]).max_paginates_per(500)
    @max_number_of_preparations = fetch_max_number_of_preparations(@collection.id)
    @collection_questions = @collection.collection_questions.includes(:collection_options)
    respond_to do |format|
      format.html # normal full page
      format.turbo_stream
    end
  end

  def search
    @q1 = @collection.items.ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per]).max_paginates_per(500)
    @max_number_of_preparations = fetch_max_number_of_preparations(@collection.id)
    render :show
  end

  def add_item_to_checkout
    @item = Item.find(params[:item_id])
    @max_number_of_preparations = fetch_max_number_of_preparations(@item.collection.id)
    render turbo_stream: turbo_stream.update("modal_content_frame") {
      render_to_string(
        partial: "items/preparations_form", locals: { max_number_of_preparations: @max_number_of_preparations },
        formats: [:html]
      )
    }
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
    return redirect_to request.referer, notice: 'No file added' if params[:files].nil?
    return redirect_to request.referer, notice: 'Only CSV files allowed' unless valid_csv_files?(params[:files])

    files = params[:files]
    identification_file = nil
    occurrence_file = nil

    files.each do |file|
      if file.original_filename.include?("identification")
        identification_file = file
      elsif file.original_filename.include?("occurrence")
        occurrence_file = file
      end
    end
    ItemImportService.new(occurrence_file, collection_id).call if occurrence_file.present?
    IdentificationImportService.new(identification_file, collection_id).call if identification_file.present?

    redirect_to request.referer, notice: 'Import Finished!'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = Collection.find(params.expect(:id))
      authorize @collection
    end

    def valid_csv_files?(files)
      files.each do |file|
        return false unless file.content_type == 'text/csv'
        return false unless File.extname(file.original_filename).downcase == ".csv"
      end
      true
    end

    # Only allow a list of trusted parameters through.
    def collection_params
      params.expect(collection: [ :division, :admin_group, :short_description, :long_description, :division_page_url, :link_to_policies, :image ])
    end
end

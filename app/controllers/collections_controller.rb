class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[ show edit update destroy search ]
  skip_before_action :authenticate_user!, only: [ :index, :show, :add_item_to_checkout, :search ]
  before_action :ensure

  def enable_preview
    session[:came_from_announcement_preview] = true
    redirect_to collections_path(preview: true)
  end

  # GET /collections or /collections.json
  def index
    @collections = Collection.all
  end

  # GET /collections/1 or /collections/1.json
  def show
    @q1 = @collection.items.includes(preparations: :requestables).ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    @collection_questions = @collection.collection_questions.includes(:collection_options)
    respond_to do |format|
      format.html # normal full page
      format.turbo_stream
    end
  end

  def search
    @q1 = @collection.items.ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per]).max_paginates_per(500)
    render :show
  end

  def add_item_to_checkout
    @item = Item.find(params[:item_id])
    render turbo_stream: turbo_stream.update("modal_content_frame") {
      render_to_string(
        partial: "items/preparations_form",
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

  def delete_image
    @collection = Collection.find(params[:id])
    authorize @collection
    @collection.image.purge if @collection.image.attached?
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("collection_image", partial: "collections/collection_image", locals: { collection: @collection }) }
      format.html { redirect_to edit_collection_path(@collection), notice: "Image deleted successfully." }
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
    item_result = {errors:0, note: []}
    identification_result = {errors:0, note: []}
    item_result = ItemImportService.new(occurrence_file, collection_id, current_user).call if occurrence_file.present?
    identification_result = IdentificationImportService.new(identification_file, collection_id, current_user).call if identification_file.present?
    errors = item_result[:errors] + identification_result[:errors]
    note = item_result[:note] + identification_result[:note]
    status = errors > 0 ? "completed with errors" : "completed"
    ItemImportLog.create(date: DateTime.now, user: current_user.name_with_email, collection_id: collection_id, status: status, note: note)
    if errors > 0
      flash[:alert] = "Import finished with #{errors} error(s). Please check reports for details"
      flash[:alert_no_timeout] = true  # Add flag to disable timeout
    else
      flash[:notice] = "Import finished successfully."
      flash[:notice_no_timeout] = true  # Add flag to disable timeout
    end
    redirect_to request.referer
  end

  private


    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = Collection.find(params[:id])
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
      params.require(:collection).permit(:division, :admin_group, :short_description, :long_description, :division_page_url, :link_to_policies, :image) 
    end

    def search_params
      params.permit(:q1, :commit)
    end
end

class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[ show edit update destroy search ]
  skip_before_action :auth_user, only: [ :index, :show, :search ]
  # before_action :set_redirection_url, only: [ :index, :show, :search ]
  before_action :ensure

  def enable_preview
    session[:came_from_announcement_preview] = true
    redirect_to collections_path(preview: true)
  end

  # GET /collections or /collections.json
  def index
    @collections = Collection.includes(:image_attachment).order(:division)
    authorize @collections
  end

  # GET /collections/1 or /collections/1.json
  def show
    @q1 = @collection.items.includes(:current_identification, :preparations).ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    @collection_questions = @collection.collection_questions.includes(:collection_options)
    # Preload checkout's requestables to avoid N+1 queries in the preparation_in_checkout helper
    @checkout&.requestables&.load
    respond_to do |format|
      format.html # normal full page
      format.turbo_stream
    end
  end

  def search
    @q1 = @collection.items.includes(:current_identification, :preparations).ransack(params[:q1])
    @items = @q1.result.page(params[:page]).per(params[:per]).max_paginates_per(500)
    # Preload checkout's requestables to avoid N+1 queries in the preparation_in_checkout helper
    @checkout&.requestables&.includes(:item, :preparation)&.load
    render :show
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
        # create preferences for the collection
        pref_errors = create_app_preferences(@collection)
        notice_message = if pref_errors
          "Collection was successfully created, but there were errors creating App Preferences. Please contact support."
        else
          "Collection was successfully created. Set up App Preferences for the collection."
        end
        format.html { redirect_to @collection, notice: notice_message }
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
    errors = 0

    files.each do |file|
      if file.original_filename.include?("identification")
        identification_file = file
      elsif file.original_filename.include?("occurrence")
        occurrence_file = file
      end
    end
    if occurrence_file.present?
      item_result = {errors:0, note: []}
      item_result = ItemImportService.new(occurrence_file, collection_id, current_user).call
      create_import_log_record(item_result, collection_id, 'Item')
      errors += item_result[:errors]
    end
    if identification_file.present?
      identification_result = {errors:0, note: []}
      identification_result = IdentificationImportService.new(identification_file, collection_id, current_user).call
      create_import_log_record(identification_result, collection_id, 'Identification')
      errors += identification_result[:errors]
    end
    
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

    def create_import_log_record(result, collection_id, import_type)
      if result[:errors] > 0
        status = "completed with errors"
        note = result[:note]
      else
        status = "completed"
        note = ["#{import_type} import completed successfully."]
      end
      ItemImportLog.create(date: DateTime.now, user: current_user.name_with_email, collection_id: collection_id, status: status, note: note)
    end

    def create_app_preferences(collection)
      # intentionally use all distinct AppPreferences as template/default preferences to copy into this new collection
      app_prefs = AppPreference.distinct(:name).pluck(:name, :description, :pref_type)
      pref_errors = false
      app_prefs.each do |name, description, pref_type|
        app_pref = AppPreference.create(collection: collection, name: name, description: description, pref_type: pref_type, value: nil)
        unless app_pref.persisted?
          Rails.logger.error "Failed to create AppPreference: #{app_pref.errors.full_messages.join(', ')}"
          pref_errors = true
        end
      end
      pref_errors
    end

    # Only allow a list of trusted parameters through.
    def collection_params
      params.require(:collection).permit(:division, :admin_group, :short_description, :long_description, :division_page_url, :link_to_policies, :image) 
    end

    def search_params
      params.permit(:q1, :commit)
    end
end

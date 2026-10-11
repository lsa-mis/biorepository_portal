class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[ show edit update destroy search ]
  skip_before_action :authenticate_user!, only: [ :index, :show, :search ]

  # GET /collections or /collections.json
  def index
    @collections = Collection.includes(image_attachment: :blob).order(:division)
    authorize @collections
  end

  # GET /collections/1 or /collections/1.json
  def show
    log_postgres_global_session_stats
    # 1. Eager load everything used in the accordion and table
    @q1 = @collection.items.includes(
      :collection,             # For item.collection.division
      :current_identification, # For item.display_name
      :preparations            # For the table and the checkout helper
    ).ransack(params[:q1])

    @items = @q1.result.page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    
    @collection_questions = @collection.collection_questions.includes(:collection_options)

    # 2. Preload checkout requestables (Foreign keys are enough since helper only checks IDs)
    @checkout&.requestables&.load

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def search
    log_postgres_global_session_stats
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
        session[:collection_ids] << @collection.id
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
    session[:collection_ids].delete(@collection.id)
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
    authorize Collection, :import?
    collection = Collection.find(params[:collection_id])
    files = params[:files]
    return redirect_back(fallback_location: collection_path(collection), notice: 'No file added') if files.blank?
    return redirect_back(fallback_location: collection_path(collection), notice: 'Only CSV files allowed') unless valid_csv_files?(files)

    occurrence_file = files.find { |file| file.original_filename.downcase.include?("occurrence") }
    identification_file = files.find { |file| file.original_filename.downcase.include?("identification") }
    if occurrence_file.nil? && identification_file.nil?
      return redirect_back(fallback_location: collection_path(collection),
                           alert: 'File names must include "occurrence" or "identification"')
    end

    # Occurrences are imported first so identifications can be linked to new items
    errors = 0
    errors += run_import(ItemImportService, occurrence_file, collection, 'Item') if occurrence_file
    errors += run_import(IdentificationImportService, identification_file, collection, 'Identification') if identification_file

    if errors > 0
      flash[:alert] = "Import finished with #{errors} error(s). Please check reports for details"
      flash[:alert_no_timeout] = true  # Add flag to disable timeout
    else
      flash[:notice] = "Import finished successfully."
      flash[:notice_no_timeout] = true  # Add flag to disable timeout
    end
    redirect_back(fallback_location: collection_path(collection))
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

    def run_import(service_class, file, collection, import_type)
      result = service_class.new(file, collection.id, current_user).call
      create_import_log_record(result, collection.id, import_type)
      result[:errors]
    end

    def create_import_log_record(result, collection_id, import_type)
      if result[:errors] > 0
        status = "completed with errors"
        note = result[:note]
      else
        status = "completed"
        note = ["#{import_type} import completed successfully. Total time: #{result[:time]} minutes."]
      end
      ItemImportLog.create(date: DateTime.now, user: current_user.name_with_email, collection_id: collection_id, status: status, note: note)
    end

    def create_app_preferences(collection)
      # intentionally use all distinct AppPreferences as template/default preferences to copy into this new collection
      app_prefs = AppPreference.select(:name, :description, :pref_type, :placeholder).distinct.pluck(:name, :description, :pref_type, :placeholder)
      pref_errors = false
      app_prefs.each do |name, description, pref_type, placeholder|
        app_pref = AppPreference.create(collection: collection, name: name, description: description, pref_type: pref_type, placeholder: placeholder, value: nil)
        unless app_pref.persisted?
          Rails.logger.error "Failed to create AppPreference: #{app_pref.errors.full_messages.join(', ')}"
          pref_errors = true
        end
      end
      pref_errors
    end

    # Only allow a list of trusted parameters through.
    def collection_params
  params.require(:collection).permit(:division, :admin_group, :short_description, 
    :long_description, :division_page_url, :link_to_policies, :image,
    :no_loan_requests)
end

    def search_params
      params.permit(:q1, :commit)
    end
end

class AppPreferencesController < ApplicationController
  before_action :set_pref_types, only: %i[ index new create]

  def enable_preview
    # session[:allow_preview] = true
    redirect_to app_prefs_path(preview: true)
  end

  # GET /app_preferences or /app_preferences.json
  def index
    @app_preference = AppPreference.new
    authorize AppPreference
    @app_preferences = AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type)
  end

  def app_prefs
    # unless params[:preview] && session.delete(:allow_preview)
    #   redirect_to announcements_path, alert: "You must access this preview from the announcements page." and return
    # end
    
    @collections = Collection.where(id: session[:collection_ids])
    @app_prefs = AppPreference.where(collection_id: session[:collection_ids]).order(:pref_type, :description)
    authorize @app_prefs
  end

  def save_app_prefs
    @app_prefs = AppPreference.where(collection_id: session[:collection_ids])
    authorize @app_prefs
    @app_prefs.where(pref_type: 'boolean').update(value: "0")
    if params[:app_prefs].present?
      params[:app_prefs].each do |collection, p|
        collection_id = collection.to_i
        p.each do |k, v|
          app_pref = AppPreference.find_by(collection_id: collection_id, name: k)
          unless app_pref&.update(value: v)
            flash.now[:alert] = "Error updating app preference: #{app_pref&.errors&.full_messages&.join(', ') || 'Preference not found.'}"
            @collections = Collection.where(id: session[:collection_ids])
            @app_prefs = AppPreference.where(collection_id: session[:collection_ids]).order(:pref_type, :description)
            render :app_prefs, status: :unprocessable_entity and return
          end
        end
      end
    end
    redirect_to app_prefs_path, notice: "Preferences are updated."
  end

  # GET /app_preferences/new
  def new
    @app_preference = AppPreference.new
    authorize @app_preference
  end

  # POST /app_preferences or /app_preferences.json
  def create
    # create preference for every collection
    Collection.all.each do |collection|
      @app_preference = AppPreference.new(app_preference_params)
      authorize @app_preference
      @app_preference.collection_id = collection.id
      unless @app_preference.save
        @app_preferences = AppPreference.distinct.pluck(:name, :description, :pref_type)
        flash.now[:alert] = "Error creating app preference."
        return
      end
    end
    flash.now[:notice] =  "App preference was successfully created."
    @app_preference = AppPreference.new
    @app_preferences = AppPreference.distinct.pluck(:name, :description, :pref_type)
  end

  def delete_preference
    @app_preferences = AppPreference.where(name: params[:name])
    authorize @app_preferences

    respond_to do |format|
      if @app_preferences.destroy_all
        format.html { redirect_to app_preferences_path, notice: "Preference was deleted." }
      else
        format.html { render :app_preferences_path, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_collections
      @collections = Collection.where(id: session[:collection_ids])
    end

    def set_pref_types
      @pref_types = AppPreference.pref_types.keys
    end

    # Only allow a list of trusted parameters through.
    def app_preference_params
      params.require(:app_preference).permit(:name, :description, :value, :pref_type, :collection_id)
    end
end

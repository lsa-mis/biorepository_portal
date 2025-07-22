class AppPreferencesController < ApplicationController
  before_action :set_pref_types, only: %i[ index new create]

  def enable_preview
    redirect_to app_prefs_path(preview: true)
  end

  # GET /app_preferences or /app_preferences.json
  def index
    @app_preference = AppPreference.new
    authorize AppPreference
    @app_preferences = []
    AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type).each {|pref| @app_preferences << pref + ["no"]}
    GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type).each {|pref| @app_preferences << pref + ["yes"]}
  end

  def app_prefs
    @collections = Collection.where(id: session[:collection_ids])
    @app_prefs = AppPreference.where(collection_id: session[:collection_ids]).order(:pref_type, :description)
    @global_prefs = GlobalPreference.all.order(:pref_type, :description)
    authorize @app_prefs
    authorize @global_prefs
  end

  def save_app_prefs
    if params[:global_prefs].present?
      @app_prefs = GlobalPreference.all
      authorize @app_prefs
      @app_prefs.where(pref_type: 'boolean').update(value: "0")
      params[:global_prefs].each do |k, v|
        app_pref = GlobalPreference.find_by(name: k)
        if app_pref.pref_type == "image" && v.present?
          app_pref.image.attach(v)
          next
        else
          unless app_pref&.update(value: v)
            flash.now[:alert] = "Error updating global preference: #{app_pref&.errors&.full_messages&.join(', ') || 'Preference not found.'}"
            @global_prefs = GlobalPreference.all.order(:pref_type, :description)
            render :global_prefs, status: :unprocessable_entity and return
          end
        end
      end
    elsif params[:app_prefs].present?
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
    @app_preferences = []
    if params[:global_preference].present?
      # Create a global preference
      @app_preference = GlobalPreference.new(app_preference_params)
      authorize @app_preference
      unless @app_preference.save
        AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["no"]}
        GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["yes"]}
        flash.now[:alert] = "Error creating app preference."
        return
      end
    else
      # create preference for every collection
      Collection.all.each do |collection|
        @app_preference = AppPreference.new(app_preference_params)
        authorize @app_preference
        @app_preference.collection_id = collection.id
        unless @app_preference.save
          AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["no"]}
          GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["yes"]}
          flash.now[:alert] = "Error creating app preference."
          return
        end
      end
    end
    flash.now[:notice] =  "App preference was successfully created."
    @app_preference = AppPreference.new
    AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["no"]}
    GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type).map {|pref| @app_preferences << pref + ["yes"]}
  end

  def delete_preference
    if params[:global] == "no"
      @app_preferences = AppPreference.where(name: params[:name])
    elsif params[:global] == "yes"
      @app_preferences = GlobalPreference.where(name: params[:name])
    end
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

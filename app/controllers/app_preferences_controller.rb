class AppPreferencesController < ApplicationController
  LOAN_REQUESTS_POLICY_PARAM = "loan_requests_policy"
  LOAN_REQUESTS_ALLOWED = "allowed"
  INFORMATION_REQUESTS_ONLY = "information_requests_only"

  before_action :set_pref_types, only: %i[ index new create]

  # GET /app_preferences or /app_preferences.json
  def index
    @app_preference = AppPreference.new
    authorize AppPreference
    @app_preferences = []
    AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["no"]}
    GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["yes"]}
  end

  def app_prefs
    @collections = editable_collections
    @app_prefs = editable_app_preferences.order(:pref_type, :description)
    @app_prefs_by_collection = @app_prefs.group_by(&:collection_id)
    @global_prefs = GlobalPreference.includes(:image_attachment).all.order(:pref_type, :description)
    authorize @app_prefs
    authorize @global_prefs
  end

  def save_app_prefs
    if params[:global_prefs].present?
      @app_prefs = GlobalPreference.all
      authorize @app_prefs
      @app_prefs.where(pref_type: 'boolean').update_all(value: "0")
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
      @app_prefs = editable_app_preferences
      authorize @app_prefs
      @app_prefs.where(pref_type: 'boolean').update_all(value: "0")
      params[:app_prefs].each do |collection, p|
        collection_id = collection.to_i
        p.each do |k, v|
          pref_name, pref_value = app_preference_update_value(k, v)
          next if pref_name.nil?

          app_pref = @app_prefs.find_by(collection_id: collection_id, name: pref_name)
          unless app_pref&.update(value: pref_value)
            flash.now[:alert] = "Error updating app preference: #{app_pref&.errors&.full_messages&.join(', ') || 'Preference not found.'}"
            @collections = editable_collections
            @app_prefs = editable_app_preferences.order(:pref_type, :description)
            @app_prefs_by_collection = @app_prefs.group_by(&:collection_id)
            render :app_prefs, status: :unprocessable_entity and return
          end
        end
      end
      sync_no_loan_requests_preferences(@app_prefs, params[:app_prefs])
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
        AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["no"]}
        GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["yes"]}
        flash.now[:alert] = "Error creating app preference."
        return
      end
    elsif params[:app_preference].present?
      # create preference for every collection
      Collection.all.each do |collection|
        @app_preference = collection.app_preferences.build(app_preference_params.except(:collection_id))
        authorize @app_preference
        unless @app_preference.save
          AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["no"]}
          GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["yes"]}
          flash.now[:alert] = "Error creating app preference."
          return
        end
      end
    end
    flash.now[:notice] =  "App preference was successfully created."
    @app_preference = AppPreference.new
    AppPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["no"]}
    GlobalPreference.distinct.order(:name).pluck(:name, :description, :pref_type, :placeholder).each {|pref| @app_preferences << pref + ["yes"]}
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

  def delete_image
    @preference = GlobalPreference.find(params[:pref_id])
    authorize @preference
    
    if @preference.image.attached?
      @preference.image.purge
      flash[:notice] = "Image deleted successfully."
    else
      flash[:alert] = "No image found to delete."
    end
    
    redirect_to app_prefs_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_pref_types
      @pref_types = AppPreference.pref_types.keys
    end

    def editable_collections
      if session[:role] == "developer" || session[:role] == "super_admin"
        Collection.order(:division)
      else
        Collection.where(id: session[:collection_ids]).order(:division)
      end
    end

    def editable_app_preferences
      if session[:role] == "developer" || session[:role] == "super_admin"
        AppPreference.all
      else
        AppPreference.where(collection_id: session[:collection_ids])
      end
    end

    def sync_no_loan_requests_preferences(app_prefs, submitted_prefs)
      collection_ids = app_prefs.where(name: "no_loan_requests").distinct.pluck(:collection_id)
      return if collection_ids.empty?

      policy_updates = submitted_prefs.to_unsafe_h.filter_map do |collection_id, preferences|
        collection_id = collection_id.to_i
        next unless collection_ids.include?(collection_id)

        no_loan_requests = no_loan_requests_from_policy(preferences[LOAN_REQUESTS_POLICY_PARAM])
        next if no_loan_requests.nil?

        [collection_id, no_loan_requests]
      end

      policy_updates.each do |collection_id, no_loan_requests|
        Collection.where(id: collection_id).update_all(no_loan_requests: no_loan_requests)
      end
    end

    def app_preference_update_value(param_name, value)
      if param_name == LOAN_REQUESTS_POLICY_PARAM
        no_loan_requests = no_loan_requests_from_policy(value)
        return if no_loan_requests.nil?

        ["no_loan_requests", no_loan_requests ? "1" : "0"]
      else
        [param_name, value]
      end
    end

    def no_loan_requests_from_policy(policy)
      case policy
      when LOAN_REQUESTS_ALLOWED
        false
      when INFORMATION_REQUESTS_ONLY
        true
      end
    end

    # Only allow a list of trusted parameters through.
    def app_preference_params
      params.require(:app_preference).permit(:name, :description, :value, :pref_type, :placeholder, :collection_id)
    end
end

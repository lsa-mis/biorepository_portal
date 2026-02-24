class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization
  unless Rails.env.development?
    rescue_from StandardError, with: :render_500
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
  end
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_render_checkout
  before_action :initialize_checkout, unless: :skip_checkout_initialization?
  before_action :make_q

  def pundit_user
    whitelisted_params = params.permit(:id, :collection_id, :preview)
    { user: current_user, role: session[:role], collection_ids: session[:collection_ids], params: whitelisted_params }
  end

  def delete_attachment
    delete_file = ActiveStorage::Attachment.find(params[:id])
    delete_file.purge
    redirect_back(fallback_location: request.referer)
  end
  
  private

  def render_404
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  def render_500(exception)
    # Prevent infinite loops by checking if we're already handling an error
    return if @handling_error
    @handling_error = true
    
    # Log the error for debugging
    Rails.logger.error "Internal Server Error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if exception.backtrace
    
    begin
      respond_to do |format|
        format.html { render 'errors/internal_server_error', status: :internal_server_error, layout: 'application' }
        format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
      end
    rescue => e
      # If rendering the error page fails, fall back to a simple response
      Rails.logger.error "Error rendering error page: #{e.message}"
      render plain: "Internal Server Error", status: :internal_server_error
    ensure
      @handling_error = false
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(collections_path)
  end

  def after_sign_in_path_for(resource)
    session[:merge_checkouts] = true
    if $baseURL.present?
      $baseURL
    else
      root_path
    end
  end

  def set_render_checkout
    @render_checkout = true
  end

  def skip_checkout_initialization?
    # Skip checkout initialization for API endpoints, static pages, etc.
    request.format.json? || 
    params[:controller] == 'errors' ||
    params[:action] == 'health_check'
  end

  def initialize_checkout
    # Only query database if we don't have a checkout ID in session
    if session[:checkout_id].present?
      @checkout = Checkout.find_by(id: session[:checkout_id]) unless @checkout
    end

    # Create checkout only if we still don't have one
    if @checkout.nil?
      @checkout = Checkout.create
      session[:checkout_id] = @checkout.id
    end

    # Handle user assignment efficiently
    if user_signed_in?
      user_checkout = current_user.checkout
      
      if user_checkout.present?
        # User has an existing checkout, use it
        Rails.logger.info "************************************ session[:merge_checkouts]: #{session[:merge_checkouts]}"
        Rails.logger.info "************************************ User has existing checkout with ID: #{user_checkout.id}"
        if session[:merge_checkouts] && @checkout.id != current_user.checkout.id
          merge_checkouts(@checkout, current_user.checkout)
          session.delete(:merge_checkouts)
        end
        @checkout = user_checkout
        session[:checkout_id] = @checkout.id
      elsif @checkout.user_id != current_user.id
        # Assign current checkout to user using update for efficiency
        @checkout.update(user_id: current_user.id)
      end
    end
  end

  def checkout_availability
    alert = ""
    @checkout.requestables.includes(:item, :preparation).each do |requestable|
      preparation = requestable.preparation
      item = requestable.item
      if item.present?
        if preparation.present?
          if preparation.count == 0
            @checkout.unavailables.create(item: item, preparation_type: requestable.preparation_type)
            alert += "#{requestable.preparation_type} "
            requestable.destroy
          else
            requestable.update(count: preparation.count) if preparation.count < requestable.count
          end
        else
          @checkout.unavailables.create(item: item, preparation_type: requestable.preparation_type)
          alert += "#{requestable.preparation_type} "
          requestable.destroy
        end
      else
        @checkout.no_longer_availables.create(item_name: requestable.item_name, preparation_type: requestable.preparation_type, collection: requestable.collection)
        alert += "#{requestable.preparation_type} "
        requestable.destroy
      end
    end
    @checkout.unavailables.each do |unavailable|
      preparation = Preparation.find_by(item: unavailable.item, prep_type: unavailable.preparation_type)
      if preparation.present?
        if preparation.count > 0 && @checkout.requestables.find_by(preparation_id: preparation.id).present?
          unavailable.destroy
        end
      end
    end
    alert
  end

  def merge_checkouts(session_checkout, user_checkout)
    user_checkout_preparations_id = user_checkout.requestables.pluck(:preparation_id).compact
    
    requestables_to_create = []
    session_checkout.requestables.each do |requestable|
      next unless requestable.preparation_id.present?
      
      unless user_checkout_preparations_id.include?(requestable.preparation_id)
        # Collect data to create new requestables
        requestables_to_create << {
          checkout_id: user_checkout.id,
          preparation_id: requestable.preparation_id,
          saved_for_later: requestable.saved_for_later,
          count: requestable.count,
          item_id: requestable.item_id,
          preparation_type: requestable.preparation_type,
          item_name: requestable.item_name,
          collection: requestable.collection,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end
    
    # Create new requestables in bulk
    Requestable.insert_all(requestables_to_create) if requestables_to_create.any?
    
    # IMPORTANT: Delete all requestables first, then destroy the checkout
    begin
      ActiveRecord::Base.transaction do
        Requestable.where(checkout_id: session_checkout.id).delete_all
        session_checkout.destroy
      end
      Rails.logger.info "***************************** Successfully merged and deleted session checkout #{session_checkout.id}"
    rescue ActiveRecord::ActiveRecordError => e
      # Database error during transaction
      Rails.logger.error "**************************** Failed to delete session checkout #{session_checkout.id}: #{e.message}"
    rescue => e
      # Any other unexpected error
      Rails.logger.error "**************************** Unexpected error during checkout merge: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
    end
  end
  
  def make_q
    @q = Item.ransack(params[:q])
  end

  def set_redirection_url
    unless user_signed_in?
      $baseURL = request.fullpath
    end
  end

  def ensure
    if params[:preview] == "true"
      unless session.delete(:came_from_announcement_preview)
        redirect_to announcements_path, alert: "You must access this preview from the announcements page."
      end
    end
  end

end

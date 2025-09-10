class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization
  rescue_from StandardError, with: :render_500
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_render_checkout
  before_action :initialize_checkout
  before_action :make_q

  def pundit_user
    whitelisted_params = params.permit(:id, :collection_id, :preview)
    { user: current_user, role: session[:role], collection_ids: session[:collection_ids], params: whitelisted_params }
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
    # Set flag to trigger checkout merging on next request (not during SAML callback)
    session[:needs_checkout_merge] = true
    
    if $baseURL.present?
      $baseURL
    else
      root_path
    end
  end

  def set_render_checkout
    @render_checkout = true
  end

  def initialize_checkout
    # Simple approach: just ensure a checkout exists
    @checkout = session[:checkout_id].present? ? Checkout.find_by(id: session[:checkout_id]) : nil

    if @checkout.nil?
      @checkout = Checkout.create
      session[:checkout_id] = @checkout.id
    end

    # For signed-in users, handle checkout merging only once after sign-in
    if user_signed_in? && session[:needs_checkout_merge]
      handle_user_checkout_merging
      session.delete(:needs_checkout_merge)
    elsif user_signed_in? && current_user.checkout.present?
      # User already has a checkout, use it
      @checkout = current_user.checkout
      session[:checkout_id] = @checkout.id
    elsif user_signed_in? && @checkout.user_id.nil?
      # Assign current session checkout to user (simple case)
      @checkout.update_column(:user_id, current_user.id)
    end
  end

  def handle_user_checkout_merging
    user_checkout = current_user.checkout
    session_checkout = @checkout
    
    if user_checkout.present? && session_checkout.present? && user_checkout.id != session_checkout.id
      # Both checkouts exist and are different - merge session into user's checkout
      if session_checkout.requestables.any?
        merge_checkouts(session_checkout, user_checkout)
      else
        # Session checkout is empty, just destroy it
        session_checkout.destroy
      end
      @checkout = user_checkout
      session[:checkout_id] = user_checkout.id
    elsif user_checkout.present?
      # User has checkout, use it
      @checkout = user_checkout
      session[:checkout_id] = user_checkout.id
    elsif session_checkout.user_id.nil?
      # Assign current session checkout to user
      session_checkout.update_column(:user_id, current_user.id)
    end
  end

  def merge_checkouts(session_checkout, user_checkout)
    # Get all preparation IDs in one query to avoid N+1
    user_checkout_preparation_ids = user_checkout.requestables.pluck(:preparation_id).compact
    
    # Use includes to preload preparations and avoid N+1 queries
    session_requestables = session_checkout.requestables.includes(:preparation)

    requestables_to_create = []
    session_requestables.each do |requestable|
      next unless requestable.preparation_id.present?
      
      unless user_checkout_preparation_ids.include?(requestable.preparation_id)
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
    
    # Bulk insert to reduce database calls
    Requestable.insert_all(requestables_to_create) if requestables_to_create.any?
    
    # Delete all requestables first, then destroy the checkout
    session_checkout.requestables.delete_all
    session_checkout.destroy
  end

  def checkout_availability
    alert = ""
    @checkout.requestables.includes(:item).each do |requestable|
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

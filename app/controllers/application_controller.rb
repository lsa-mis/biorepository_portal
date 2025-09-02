class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization
  # rescue_from StandardError, with: :render_500
  # rescue_from ActiveRecord::RecordNotFound, with: :render_404
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
    @checkout ||= Checkout.find_by(id: session[:checkout_id])

    if @checkout.nil?
      @checkout = Checkout.create
      session[:checkout_id] = @checkout.id
    end

    if user_signed_in?
      if current_user.checkout.present?
        unless @checkout.id == current_user.checkout.id
          merge_checkouts(@checkout, current_user.checkout)
        end
        @checkout = current_user.checkout
        session[:checkout_id] = @checkout.id
      else
        @checkout.user = current_user
        @checkout.save
      end
    end
  end

  def merge_checkouts(old_checkout, new_checkout)
    new_checkout_preparations_id = new_checkout.requestables.pluck(:preparation_id)
    old_checkout.requestables.each do |requestable|
      preparation_id = requestable.preparation.id
      unless new_checkout_preparations_id.include?(preparation_id)
        # If it doesn't exist, create a new requestable in the new checkout
        new_checkout.requestables.create(preparation: requestable.preparation, saved_for_later: requestable.saved_for_later, count: requestable.count)
      end
    end
    old_checkout.destroy
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

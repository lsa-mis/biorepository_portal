class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_render_checkout
  before_action :initialize_checkout
  before_action :make_q

  def pundit_user
    { user: current_user, role: session[:role], collection_ids: session[:collection_ids] }
  end
  
  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
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
  def make_q
    @q = Item.ransack(params[:q])
  end

end

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  def pundit_user
    { user: current_user, role: session[:role], collection_ids: session[:collection_ids] }
  end

  def search
    index
    render :index
  end
  
  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

end

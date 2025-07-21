class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure

  def enable_preview
    session[:came_from_announcement_preview] = true
    redirect_to about_path(preview: true)
  end
  
  def about
    @items = Item.order("RANDOM()").limit(6)
  end
end

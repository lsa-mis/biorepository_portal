class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure

  def enable_preview
    session[:came_from_announcement_preview] = true
    redirect_to about_path(preview: true)
  end
  
  def about
    home_page_image = GlobalPreference.find_by(name: 'home_page_image')
    @home_page_image = home_page_image&.image&.attached? ? home_page_image.image : nil
    @items = Item.order("RANDOM()").limit(6)
  end
end

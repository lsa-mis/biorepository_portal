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
    
    total_count = Rails.cache.fetch('items_count', expires_in: 1.hour) { Item.count }
    if total_count > 6
      # Generate 6 random IDs and fetch those specific items
      item_ids = Item.pluck(:id).sample(6)
      @items = Item.where(id: item_ids)
    else
      @items = Item.limit(6)
    end
  end
end

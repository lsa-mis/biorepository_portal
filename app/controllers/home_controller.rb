class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  
  def about
    @items = Item.order("RANDOM()").limit(6)
  end
end

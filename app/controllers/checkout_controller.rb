class CheckoutController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure

  def enable_preview
    session[:came_from_announcement_preview] = true
    redirect_to checkout_path(preview: true)
  end
 
  def show
    @render_checkout = false
  end

  def add
    @preparation = Preparation.find(params[:id])
    in_checkout = @checkout.requestables.find_by(preparation_id: @preparation.id)&.count.to_i
    available = [@preparation.count - in_checkout, 0].max
    if available <= 0
      flash.now[:alert] = "No available preparations to add to checkout."
      count = 0
    else
      count = 1
    end
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if !current_requestable
      @checkout.requestables.create(preparation: @preparation, count: count)
    else
        current_requestable.update(count: current_requestable.count + count)
    end

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Preparation added to checkout."
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash'),
                              turbo_stream.update(
                                "checkout_item_#{@preparation.item_id}",
                                partial: 'items/item_card',
                                locals: { item: @preparation.item }
                              ),
                              turbo_stream.update(
                                "checkout_item_in_collection#{@preparation.item_id}",
                                partial: 'collections/item_card',
                                locals: { item: @preparation.item }
                              ),
                              turbo_stream.update(
                                "checkout_item_row_#{@preparation.item_id}",
                                partial: 'collections/preparation_for_checkout',
                                locals: { item: @preparation.item }
                              )]
      end
    end
  end

  def change
    @preparation = Preparation.find(params[:id])
    count = params[:count].to_i
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if current_requestable 
      if count > 0
        current_requestable.update(count: count)
        notice = "Preparation edited checkout."
      elsif count <= 0
        current_requestable.destroy
        notice = "Preparation removed from checkout."
      end
    else
      notice = "No matching preparation found in checkout."
    end
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                                                   turbo_stream.update('total', partial: 'checkout/total'),
                                                   turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash')]
      end
    end

  end

  def remove
    Requestable.find(params[:id])&.destroy
    flash.now[:notice] = "Preparation removed from checkout."
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [turbo_stream.replace('checkout',
                                                  partial: 'checkout/checkout',
                                                  locals: { checkout: @checkout }),
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash')]
      end
    end
  end

  def remove_preparation
    @preparation = Preparation.find(params[:id])
    requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if requestable
      requestable.destroy
      flash.now[:notice] = "Preparation removed from checkout."
    else
      flash.now[:alert] = "No matching preparation found in checkout."
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash'),
                              turbo_stream.update(
                                "checkout_item_#{@preparation.item_id}",
                                partial: 'items/item_card',
                                locals: { item: @preparation.item }
                              ),
                              turbo_stream.update(
                                "checkout_item_in_collection#{@preparation.item_id}",
                                partial: 'collections/item_card',
                                locals: { item: @preparation.item }
                              ),
                              turbo_stream.update(
                                "checkout_item_row_#{@preparation.item_id}",
                                partial: 'collections/preparation_for_checkout',
                                locals: { item: @preparation.item }
                              )]
      end
    end
  end

  def save_for_later
    @preparation = Preparation.find(params[:id])
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if current_requestable
      current_requestable.update(saved_for_later: true)
      flash.now[:notice] = "Preparation saved for later."
    else
      flash.now[:alert] = "Preparation not found in checkout."
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash')]
      end
    end
  end

  def move_back
    @preparation = Preparation.find(params[:id])
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if current_requestable
      current_requestable.update(saved_for_later: false)
      flash.now[:notice] = "Preparation moved back to checkout."
    else
      flash.now[:alert] = "Preparation not found in saved for later."
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('total1', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash')]
      end
    end
  end
end

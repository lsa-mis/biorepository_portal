class CheckoutController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    @render_checkout = false
  end

  def add
    @preparation = Preparation.find(params[:id])
    count = params[:count].to_i
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if current_requestable && count > 0
      current_requestable.update(count: current_requestable.count + count)
    elsif count <= 0
      current_requestable.destroy
    else
      @checkout.requestables.create(preparation: @preparation, count:)
    end
    @max_number_of_preparations = fetch_max_number_of_preparations(@preparation.item.collection.id)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Preparation added to checkout."
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                              turbo_stream.replace(@preparation),
                              turbo_stream.update('total', partial: 'checkout/total'),
                              turbo_stream.update('flash', partial: 'layouts/flash'),
                              turbo_stream.update(
                                "checkout_item_#{@preparation.item_id}",
                                partial: 'collections/item_card',
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
    @max_number_of_preparations = fetch_max_number_of_preparations(@preparation.item.collection.id)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                                                   turbo_stream.update('total', partial: 'checkout/total'),
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
                              turbo_stream.update('flash', partial: 'layouts/flash')]
      end
    end
  end
end

class CheckoutController < ApplicationController
  def show
    @render_checkout = false
  end

  def add
    @preparation = Preparation.find(params[:id])
    count = params[:count].to_i
    current_requestable = @checkout.requestables.find_by(preparation_id: @preparation.id)
    if current_requestable && count > 0
      current_requestable.update(count:)
    elsif count <= 0
      current_requestable.destroy
    else
      @checkout.requestables.create(preparation: @preparation, count:)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [turbo_stream.replace('checkout',
                                                   partial: 'checkout/checkout',
                                                   locals: { checkout: @checkout }),
                              turbo_stream.replace(@preparation)]
      end
    end
  end

  def remove
    Requestable.find(params[:id])&.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('checkout',
                                                  partial: 'checkout/checkout',
                                                  locals: { checkout: @checkout })
      end
    end
  end
end

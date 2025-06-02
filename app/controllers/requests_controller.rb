class RequestsController < ApplicationController

  def information_request
    @information_request = InformationRequest.new
    @send_to = Collection.pluck(:admin_group).compact
  end

  def send_information_request
    message = params[:information_request][:question]
    send_to = params[:information_request][:send_to]
    if params[:include_items_from_checkout] == "1"
      # Assuming you have a method to get items from checkout
      items = get_items_from_checkout
      message += "\n\nItems from checkout:\n" + items.join("\n")
    end
    @information_request = InformationRequest.new(
      question: message,
      send_to: send_to,
      user: current_user
    )
    if @information_request.save
      RequestMailer.with(
        information_request: @information_request,
        send_to: send_to,
        user: current_user,
        message: message
      ).send_information_request.deliver_now
      redirect_to root_path, notice: "Information request sent successfully."
    else
      flash.now[:alert] = "Failed to send information request. Please try again."
      render :information_request
    end
  end
end

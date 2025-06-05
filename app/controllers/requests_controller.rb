class RequestsController < ApplicationController

  def information_request
    @information_request = InformationRequest.new
    @send_to = Collection.pluck(:admin_group)
    generic_email = AppPreference.find_by(name: "generic_contact_email")&.value
    @send_to << generic_email if generic_email.present?
    @send_to.compact!
    @send_to.uniq!
  end

  def send_information_request
    checkout_items = ""
    message = params[:information_request][:question]
    send_to = params[:information_request][:send_to]
    if params[:include_items_from_checkout] == "1"
      # Assuming you have a method to get items from checkout
      checkout_items = get_checkout_items
    end

    @information_request = InformationRequest.new(
      question: message,
      send_to: send_to,
      user: current_user,
      checkout_items: checkout_items
    )
    if @information_request.save
      RequestMailer.with(
        information_request: @information_request,
        send_to: send_to,
        user: current_user,
        message: message,
        checkout_items: checkout_items
      ).send_information_request.deliver_now
      redirect_to root_path, notice: "Information request sent successfully."
    else
      flash.now[:alert] = "Failed to send information request."
      @send_to = Collection.pluck(:admin_group).compact
      render :information_request
    end
  end

  def get_checkout_items
    checkout_items = ""
    @checkout.requestables.each do |requestable|
      preparation = requestable.preparation
      item = preparation.item
      checkout_items += "#{item.collection.division}, occurrenceID: #{item.occurrence_id}; preparation: #{preparation.prep_type}"
      if preparation.barcode.present?
        checkout_items += "barcode: #{preparation.barcode}"
      end
      if preparation.description.present?
        checkout_items += ", description: #{preparation.description}"
      end
      checkout_items += ", count: #{requestable.count}. "
    end
    checkout_items
  end
end

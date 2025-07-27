class InformationRequestsController < ApplicationController
  before_action :set_redirection_url

  def enable
    redirect_to new_loan_request_path(preview: true)
  end

  def show_modal
    @information_request = InformationRequest.find(params[:id])
    render turbo_stream: turbo_stream.update("modal_content_frame"){
      render_to_string partial: "information_requests/review", 
        formats: [:html],
        locals: { information_request: @information_request }
    }
  end

  def show
    @information_request = InformationRequest.find(params[:id])
    @checkout_items, @collection_ids = get_checkout_items
    @user = current_user
  end

  def new
    @information_request = InformationRequest.new
    @send_to = {}    
    emails = AppPreference.joins(:collection).where(name: "collection_email_to_send_requests").where.not(value: [nil, '']).pluck("collections.division", :value)
    emails.each { |division, email| @send_to[division] = email }
    generic_email = AppPreference.find_by(name: "generic_contact_email")&.value || ""
    @send_to["Collections email"] = generic_email if generic_email.present?
  end

  def send_information_request

    checkout_items = []
    message = params[:information_request][:question]
    send_to = params[:information_request][:send_to]
    if params[:include_items_from_checkout] == "1"
      # Assuming you have a method to get items from checkout
      checkout_items, collection_ids = get_checkout_items
    end
    @information_request = InformationRequest.new(
      question: message,
      send_to: send_to,
      user: current_user,
      checkout_items: checkout_items,
      collection_ids: collection_ids
    )
    if @information_request.save
      RequestMailer.with(
        information_request: @information_request,
        send_to: send_to,
        user: current_user,
        message: message,
        checkout_items: checkout_items
      ).send_information_request.deliver_now
      RequestMailer.with(
        information_request: @information_request,
        user: current_user,
        message: message,
        checkout_items: checkout_items
      ).confirmation_information_request.deliver_now
      redirect_to faqs_path, notice: "Information request sent successfully."
    else
      flash.now[:alert] = "Failed to send information request."
      @send_to = Collection.pluck(:admin_group).compact
      render :new
    end
  end

  private

end

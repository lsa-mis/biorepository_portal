class RequestMailer < ApplicationMailer

  def send_information_request
    @message = params[:message]
    send_to = params[:send_to]
    @user = params[:user]
    @checkout_items = params[:checkout_items].split('. ') if params[:checkout_items].present?
    subject = "BioRepository Portal Information Request - #{Date.today}"
    mail(to: send_to, subject: subject)
  end

end

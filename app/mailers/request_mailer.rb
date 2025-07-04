class RequestMailer < ApplicationMailer

  def send_information_request
    @message = params[:message]
    send_to = params[:send_to]
    @user = params[:user]
    @checkout_items = params[:checkout_items].split('. ') if params[:checkout_items].present?
    subject = "BioRepository Portal Information Request - #{Date.today}"
    mail(to: send_to, subject: subject)
  end

  def send_loan_request(send_to:, user:, loan_request:, csv_file: nil, pdf_file: nil)
    @user = user
    attachments["loan_request.csv"] = File.read(csv_file) if csv_file.present?
    attachments["loan_request.pdf"] = File.read(pdf_file) if pdf_file.present?
    loan_request.attachment_files.each do |file|
      attachments[file.filename.to_s] = {
        mime_type: file.content_type,
        content: file.open { |f| f.read }
      }
    end
    subject = "BioRepository Loan Request from #{user.first_name} - #{Date.today}"
    mail(to: send_to, subject: subject)
  end

  def user_confirmation_email(user, loan_request, csv_file:, pdf_file:)
    @user = user
    @loan_request = loan_request
    attachments["loan_request.csv"] = { content: File.read(csv_file), content_type: "text/csv" } if csv_file.present?
    attachments["loan_request.pdf"] = { content: File.read(pdf_file), content_type: "application/pdf" } if pdf_file.present?
    mail(
      to: @user.email,
      subject: "Confirmation: Your Loan Request Has Been Submitted"
    )
  end
end

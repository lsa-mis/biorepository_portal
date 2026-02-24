class RequestMailer < ApplicationMailer

  def send_information_request
    @message = params[:message]
    send_to = params[:send_to]
    @user = params[:user]
    @checkout_items = params[:checkout_items] if params[:checkout_items].present?
    subject = "Biorepository Portal Information Request - #{Date.today}"
    mail(to: send_to, subject: subject)
  end

  def confirmation_information_request
    @information_request = params[:information_request]
    @user = params[:user]
    @message = params[:message]
    @checkout_items = params[:checkout_items] if params[:checkout_items].present?
    collection_ids = params[:collection_ids] if params[:collection_ids].present?
    @custom_email_message = get_custom_email_messages(collection_ids, "custom_message_information_request")
    subject = "Confirmation: Your Information Request Has Been Sent"
    mail(to: @user.email, subject: subject)
  end

  def send_loan_request(send_to:, user:, loan_request:, csv_file: nil, pdf_file: nil, file_name:)
    @user = user
    effective_file_name = file_name.presence || "loan_request_#{loan_request&.id}"
    attachments["#{effective_file_name}.csv"] = { content: File.read(csv_file), content_type: "text/csv" } if csv_file.present?
    attachments["#{effective_file_name}.pdf"] = { content: File.read(pdf_file), content_type: "application/pdf" } if pdf_file.present?
    loan_request.attachment_files.each do |file|
      attachments[file.filename.to_s] = {
        mime_type: file.content_type,
        content: file.open { |f| f.read }
      }
    end
    subject = "Biorepository Loan Request from #{user.first_name} - #{Date.today}"
    mail(to: send_to, subject: subject)
  end

  def confirmation_loan_request(user, loan_request, collection_ids, csv_file:, pdf_file:, file_name:)
    @user = user
    @loan_request = loan_request
    effective_file_name = file_name.presence || "loan_request_#{loan_request&.id}"
    @custom_email_message = get_custom_email_messages(collection_ids, "custom_message_loan_request")
    attachments["#{effective_file_name}.csv"] = { content: File.read(csv_file), content_type: "text/csv" } if csv_file.present?
    attachments["#{effective_file_name}.pdf"] = { content: File.read(pdf_file), content_type: "application/pdf" } if pdf_file.present?
    mail(
      to: @user.email,
      subject: "Confirmation: Your Loan Request Has Been Submitted"
    )
  end

  private

    def get_custom_email_messages(collection_ids, message_type)
      custom_email_messages = {}
      if collection_ids.present?
        collection_ids.each do |collection_id|
          collection = Collection.find_by(id: collection_id)
          next unless collection
          collection_name = collection.division
          collection_email_message = AppPreference.find_by(name: message_type, collection_id: collection_id)&.value
          custom_email_messages[collection_name] = collection_email_message if collection_email_message.present?
        end
      end
      custom_email_messages
    end

end

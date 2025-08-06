require "csv"

class LoanRequestsController < ApplicationController
  before_action :set_redirection_url

  def enable
    redirect_to new_loan_request_path(preview: true)
  end

  def show
    @loan_request = LoanRequest.find(params[:id])
  end

  def new
    @loan_questions = LoanQuestion.all
    @loan_request = LoanRequest.new
    @checkout_items, @collection_ids = get_checkout_items
    @user = current_user
    @addresses = current_user.addresses.order(primary: :desc, created_at: :asc)

    loan_questions = LoanQuestion.includes(:loan_answers).order(:position)
	  @loan_answers = loan_questions.each_with_object({}) do |question, hash|
	    hash[question] = question.loan_answers.find { |answer| answer.user_id == current_user.id }
    end

    @collection_answers = build_collection_answers(@checkout, current_user)
  end

  def send_loan_request
    if @checkout.nil? || @checkout.requestables.empty?
      flash[:alert] = "No items in checkout."
      redirect_to root_path
      return
    end

    @checkout_items, @collection_ids = get_checkout_items

    emails = @collection_ids.map do |collection_id|
      AppPreference.find_by(
        collection_id: collection_id,
        name: "collection_email_to_send_requests"
      )&.value
    end.compact

    # Use default email from ApplicationMailer if no collection-specific emails found
    emails = [ApplicationMailer.default[:to]] unless emails.present?
    @loan_request = LoanRequest.new
    @loan_request.user = current_user
    @loan_request.send_to = emails.join(', ')
    @loan_request.checkout_items = @checkout_items
    @loan_request.collection_ids = @collection_ids

    loan_questions = LoanQuestion.includes(:loan_answers).order(:position)
    @loan_answers = loan_questions.each_with_object({}) do |question, hash|
	    hash[question] = question.loan_answers.find { |answer| answer.user_id == current_user.id }
    end

    @collection_answers = build_collection_answers(@checkout, current_user)

    # Handle general loan questions (prefix: "general")
    attach_attachments_from_answers(@loan_answers, ->(question) { "general" })

    # Handle collection-specific questions (prefix: collection name or fallback)
    @collection_answers.each_value do |qa_data|
      attach_attachments_from_answers(qa_data, ->(question) {
        question.collection&.division&.parameterize || "NA"
      })
    end

    # Check required questions
    missing_loan_answers = check_missing_answers(@loan_answers)
    missing_collection_answers = @collection_answers.any? { |_, qa_data| check_missing_answers(qa_data) }

    # Check required user info fields
    user_missing_fields = false
    user_missing_fields = true unless current_user.first_name.present?
    user_missing_fields = true unless current_user.last_name.present?
    user_missing_fields = true unless current_user.affiliation.present?

    if missing_loan_answers || missing_collection_answers|| user_missing_fields
      flash[:alert] = "Please answer all required questions before sending the loan request."
      redirect_to new_loan_request_path and return
    end

    pdf_tempfile = Tempfile.new(["loan_request", ".pdf"])
    csv_tempfile = create_csv_file(current_user)

    begin
      if @loan_request.save
        File.open(pdf_tempfile, "wb") do |file|
          file.write(PdfGenerator.new(current_user, @loan_answers, @checkout_items, @collection_answers).generate_pdf_content)
        end
        pdf_tempfile.rewind

        @loan_request.pdf_file.attach(
          io: pdf_tempfile,
          filename: "loan_request_#{@loan_request.id}.pdf",
          content_type: "application/pdf"
        )

        @loan_request.csv_file.attach(
          io: csv_tempfile,
          filename: "loan_request_#{@loan_request.id}.csv",
          content_type: "text/csv"
        )
        RequestMailer.send_loan_request(
          send_to: emails,
          user: current_user,
          loan_request: @loan_request,
          csv_file: csv_tempfile,
          pdf_file: pdf_tempfile
        ).deliver_now

        RequestMailer.confirmation_loan_request(
          current_user,
          @loan_request,
          csv_file: csv_tempfile,
          pdf_file: pdf_tempfile
        ).deliver_now

        # Clean up checkout items
        @checkout.requestables.active.delete_all

        redirect_to checkout_path, notice: "Loan request sent with CSV and PDF attached."
      else
        flash[:alert] = "Failed to create loan request. Please try again: #{@loan_request.errors.full_messages.join(', ')}"
        redirect_to new_loan_request_path
      end
    
    ensure
      csv_tempfile.close
      csv_tempfile.unlink
      pdf_tempfile.close
      pdf_tempfile.unlink
    end
  end

  private

    def create_csv_file(user)
      tempfile = Tempfile.new(["loan_request", ".csv"])

      CSV.open(tempfile.path, "w") do |csv|
        csv << [
          "User Name",
          "User Institution",
          "User Email",
          "Division",
          "Catalog Number",
          "Prep Type",
          "Count",
          "Barcode"
        ]

        @checkout.requestables.active.each do |requestable|
          csv << [
            [user.first_name, user.last_name].compact.join(" "),
            user.affiliation,
            user.email,
            requestable.preparation.item.collection.division,
            requestable.preparation.item.catalog_number,
            requestable.preparation.prep_type,
            requestable.count,
            requestable.preparation.barcode
          ]
        end
      end

      tempfile.rewind
      tempfile
    end

    def build_collection_answers(checkout, user)
      collections = Collection
                .where(id: checkout.requestables.map { |requestable| requestable.preparation.item.collection_id }.uniq)
                .includes(collection_questions: :collection_answers)
      collection_answers = {}

      collections.each do |collection|
        collection_questions = collection.collection_questions.order(:position)
        next if collection_questions.empty?

        question_answer_hash = {}
        collection_questions.each do |question|
          answer = question.collection_answers.find { |a| a.user_id == user.id }
          question_answer_hash[question] = answer
        end

        collection_answers[collection] = question_answer_hash
      end

      collection_answers
    end

    def check_missing_answers(answers_hash)
      answers_hash.each do |question, answer|
        if question.required? && (answer.blank? || answer.answer.blank?) 
          return true
        end
      end
      return false
    end

    def attach_attachments_from_answers(answers, prefix_resolver)
      answers.each do |question, answer|
        next unless question.question_type == "attachment"
        next unless answer&.attachment&.attached?

        original_blob = answer.attachment.blob

        prefix = prefix_resolver.call(question)
        index = question.position || "0"
        ext = File.extname(original_blob.filename.to_s)
        custom_filename = "#{prefix}-#{index}#{ext}"

        @loan_request.attachment_files.attach(
          io: StringIO.new(original_blob.download),
          filename: custom_filename,
          content_type: original_blob.content_type
        )
      end
    end

end

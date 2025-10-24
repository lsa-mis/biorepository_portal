require "csv"

class LoanRequestsController < ApplicationController
  before_action :set_redirection_url

  def enable
    redirect_to new_loan_request_path(preview: true)
  end

  def show
    @loan_request = LoanRequest.find(params[:id])
    authorize @loan_request
  end

  def new
    @loan_questions = LoanQuestion.all
    @loan_request = LoanRequest.new
    @user = current_user
    authorize @loan_request
  end

  def step_two
    # Check required user info fields
    required_fields = [:first_name, :last_name, :affiliation]
    missing_fields = required_fields.select { |field| current_user.send(field).blank? }

    if missing_fields.any?
      flash[:alert] = "User information is incomplete."
      redirect_to new_loan_request_path and return
    end

    @loan_answers = get_loan_answers
    authorize LoanRequest
  end

  def step_three
    @loan_answers = get_loan_answers
    missing_loan_answers = check_missing_answers(@loan_answers)
    if missing_loan_answers
      flash[:alert] = "Please answer all loan questions."
      redirect_to step_two_path and return
    end
    @collection_answers = build_collection_answers(@checkout, current_user)
    authorize LoanRequest
  end

  def step_four
    @collection_answers = build_collection_answers(@checkout, current_user)
    missing_collection_answers = @collection_answers.any? { |_, qa_data| check_missing_answers(qa_data) }
    if missing_collection_answers
      flash[:alert] = "Please answer all collection questions."
      redirect_to step_three_path and return
    end
    @addresses = current_user.addresses.order(primary: :desc, created_at: :asc)
    authorize LoanRequest
  end

  def step_five
    @loan_request = LoanRequest.new
    missing_shipping_address = check_shipping_address
    if missing_shipping_address
      flash[:alert] = @missing_fields_alert
      redirect_to step_four_path and return
    end
    alert = checkout_availability
    @checkout_items = get_checkout_items_with_ids
    authorize LoanRequest
    flash.now[:alert] = alert + " preparation(s) are no longer available and have been removed from Checkout." if alert.present?
  end

  def send_loan_request
    @shipping_address = Address.find(params[:shipping_address_id])

    if @checkout.nil? || @checkout.requestables.active.empty?
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
    authorize @loan_request
    @loan_request.user = current_user
    @loan_request.send_to = emails.join(', ')
    @loan_request.checkout_items = @checkout_items
    @loan_request.collection_ids = @collection_ids

    @loan_answers = get_loan_answers

    @collection_answers = build_collection_answers(@checkout, current_user)

    # Handle general loan questions (prefix: "general")
    attach_attachments_from_answers(@loan_answers, ->(question) { "general" })

    # Handle collection-specific questions (prefix: collection name or fallback)
    @collection_answers.each_value do |qa_data|
      attach_attachments_from_answers(qa_data, ->(question) {
        question.collection&.division&.parameterize || "NA"
      })
    end

    pdf_tempfile = Tempfile.new(["loan_request", ".pdf"])
    csv_tempfile = create_csv_file(current_user)
    
    begin
      if @loan_request.save
        File.open(pdf_tempfile, "wb") do |file|
          file.write(PdfGenerator.new(current_user, @shipping_address, @loan_answers, @checkout_items, @collection_answers).generate_pdf_content)
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
        clean_up_checkout_items

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

    def get_loan_answers
      loan_questions = LoanQuestion.includes(:loan_answers).order(:position)
      loan_questions.each_with_object({}) do |question, hash|
        hash[question] = question.loan_answers.find { |answer| answer.user_id == current_user.id }
      end
    end

    def create_csv_file(user)
      tempfile = Tempfile.new(["loan_request", ".csv"])

      CSV.open(tempfile.path, "w") do |csv|
        csv << [
          "Requester Name",
          "Requester Institution",
          "Requester Email",
          "Division",
          "Catalog Number",
          "Prep Type",
          "Count",
          "Barcode",
          "Address Line 1",
          "Address Line 2",
          "Address Line 3",
          "Address Line 4",
          "City",
          "State",
          "Country",
          "ZIP Code",
          "Phone Number",
          "Shipping Name",
          "Shipping Email"
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
            requestable.preparation.barcode,
            @shipping_address&.address_line_1,
            @shipping_address&.address_line_2,
            @shipping_address&.address_line_3,
            @shipping_address&.address_line_4,
            @shipping_address&.city,
            @shipping_address&.state,
            @shipping_address&.country,
            @shipping_address&.zip,
            @shipping_address&.phone,
            [@shipping_address&.first_name, @shipping_address&.last_name].compact.join(" "),
            @shipping_address&.email
          ]
        end
      end

      tempfile.rewind
      tempfile
    end

    def build_collection_answers(checkout, user)
      collections = Collection
                .where(id: checkout.requestables.active.map { |requestable| requestable.preparation.item.collection_id }.uniq)
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

    def check_shipping_address
      if params[:shipping_address_id].present?
        @shipping_address = Address.find(params[:shipping_address_id])
        return false
      elsif current_user.addresses.present?
        @missing_fields_alert = "Select an address to ship to."
        return true
      else
        @missing_fields_alert = "Add a Shipping address."
        return true
      end
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

    def clean_up_checkout_items
      @checkout.requestables.active.each do |requestable|
        preparation = requestable.preparation
        preparation.with_lock do
          new_count = [preparation.count - requestable.count, 0].max
          preparation.update(count: new_count)
        end
      end
      @checkout.requestables.active.delete_all
    end

end

require "csv"

class RequestsController < ApplicationController

  def information_request
    @information_request = InformationRequest.new
    @send_to = {}    
    emails = AppPreference.joins(:collection).where(name: "collection_email_to_send_requests").where.not(value: [nil, '']).pluck("collections.division", :value)
    emails.each { |division, email| @send_to[division] = email }
    generic_email = AppPreference.find_by(name: "generic_contact_email")&.value || ""
    @send_to["Collections email"] = generic_email if generic_email.present?
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

  def loan_request
    @loan_questions = LoanQuestion.all
    @loan_request = LoanRequest.new
    @checkout_items = get_checkout_items
    @user = current_user

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
    end
    
    @checkout_items = get_checkout_items

    @collections_in_checkout = @checkout.requestables
      .map { |r| r.preparation&.item&.collection }
      .compact
      .uniq
    emails = @collections_in_checkout.map do |collection|
      AppPreference.find_by(
        collection_id: collection.id,
        name: "collection_email_to_send_requests"
      )&.value
    end.compact

    @loan_request = LoanRequest.new
    @loan_request.user = current_user
    @loan_request.send_to = emails.join(', ')
    # @loan_request.save!

    loan_questions = LoanQuestion.includes(:loan_answers).order(:position)
    @loan_answers = loan_questions.each_with_object({}) do |question, hash|
	    hash[question] = question.loan_answers.find { |answer| answer.user_id == current_user.id }
    end

    @collection_answers = build_collection_answers(@checkout, current_user)

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
      redirect_to :loan_request and return
    end

    pdf_tempfile = Tempfile.new(["loan_request", ".pdf"])
    csv_tempfile = create_csv_file(current_user)

    begin
      @loan_request.save
      
      File.open(pdf_tempfile, "wb") do |file|
        file.write(PdfGenerator.new(@loan_answers, @checkout_items, @collection_answers).generate_pdf_content)
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
        csv_file: csv_tempfile,
        pdf_file: pdf_tempfile
      ).deliver_now

      RequestMailer.user_confirmation_email(
        current_user,
        @loan_request,
        csv_file: csv_tempfile,
        pdf_file: pdf_tempfile
      ).deliver_now

      # Clean up checkout items
      @checkout.requestables.destroy_all

      redirect_to root_path, notice: "Loan request sent with CSV and PDF attached."

    ensure
      csv_tempfile.close
      csv_tempfile.unlink
      pdf_tempfile.close
      pdf_tempfile.unlink
    end
  end

  private
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

        @checkout.requestables.each do |requestable|
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

end

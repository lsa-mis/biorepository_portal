class ProfilesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  ALLOWED_FIELDS = %w[first_name last_name affiliation orcid].freeze

  def show
    @collections = Collection.joins(:collection_questions).distinct
    @loan_requests = current_user.loan_requests.with_attached_pdf_file.with_attached_csv_file.order(created_at: :desc)
    @information_requests = current_user.information_requests.order(created_at: :desc)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      flash.now[:alert] = "Failed to update profile."
      render :edit, status: :unprocessable_entity
    end
  end

  def edit_field
    @user = current_user
    @field = params[:field]

    render turbo_stream: turbo_stream.update("edit_user_field_modal_content_frame") {
      render_to_string partial: "profiles/edit_single_field_form",
                      formats: [:html],
                      locals: { user: @user, field: @field }
    }
  end

  def update_field
    @user = current_user
    field = params[:field]

    if field.in?(ALLOWED_FIELDS) && @user.update(params.require(:user).permit(field))
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "user_field_#{field}",
            partial: "profiles/user_field",
            locals: {
              user: @user,
              field_name: field,
              label: field.titleize,
              value: @user[field]
            }
          )
        }
        format.html { redirect_to loan_request_path, notice: "#{field.titleize} updated." }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: loan_request_path, alert: "Failed to update field." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("edit_user_field_modal_content_frame") {
            render_to_string partial: "profiles/edit_single_field_form",
                            formats: [:html],
                            locals: { user: @user, field: field }
          }, status: :unprocessable_entity
        }
      end
    end
  end


  def loan_questions
    @loan_questions = LoanQuestion.all
    @loan_answers = current_user.loan_answers.includes(:loan_question)
    @collections = Collection.joins(:collection_questions).distinct
  end

  def update_loan_questions
    return redirect_to profile_path, alert: "No answers submitted." if params[:loan_answers].blank?

    @loan_questions = LoanQuestion.all

    @loan_questions.each do |question|
      raw_answer = params[:loan_answers][question.id.to_s]

      # Skip if nothing submitted for this question
      next if raw_answer.nil?

      # For checkboxes: join multiple values into a single string
      answer_value = raw_answer.is_a?(Array) ? raw_answer.join(", ") : strip_tags(raw_answer.strip)

      answer = question.loan_answers.find_or_initialize_by(user: current_user)
      answer.answer = answer_value
      answer.save
    end

    redirect_to profile_path, notice: "Loan questions updated successfully."
  end

  def collection_questions
    @collection = Collection.find(params[:id])
    @collection_questions = @collection.collection_questions
    @collection_answers = current_user.collection_answers.where(collection_question: @collection_questions)
  end

  def update_collection_questions
    @collection = Collection.find(params[:id])
    if params[:collection_answers].blank?
      return redirect_to profile_path, alert: "No answers submitted."
    end

    ActiveRecord::Base.transaction do
      params[:collection_answers].each do |question_id, raw_answer|
        question = CollectionQuestion.find(question_id)
        answer = current_user.collection_answers.find_or_initialize_by(collection_question: question)
        cleaned_answer = raw_answer.is_a?(Array) ? raw_answer.join(", ") : strip_tags(raw_answer.to_s.strip)
        answer.answer = cleaned_answer
        answer.save!
      end
    end

    redirect_to profile_path, notice: "Your answers have been saved."
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :affiliation, :orcid)
  end
  
end

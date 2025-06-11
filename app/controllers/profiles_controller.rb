class ProfilesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def show
    @collections = Collection.joins(:collection_questions).distinct
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

    params[:collection_answers].each do |question_id, raw_answer|
      question = CollectionQuestion.find(question_id)
      answer = current_user.collection_answers.find_or_initialize_by(collection_question: question)
      cleaned_answer = raw_answer.is_a?(Array) ? raw_answer.join(", ") : strip_tags(raw_answer.to_s.strip)
      answer.answer = cleaned_answer
      answer.save!
    end

    redirect_to profile_path, notice: "Your answers have been saved."
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :affiliation, :orcid)
  end
  
end

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

    errors = []
    @loan_questions = LoanQuestion.all

    ActiveRecord::Base.transaction do
      @loan_questions.each do |question|
        raw_answer = params[:loan_answers][question.id.to_s]

        if question.required?
          if raw_answer.blank? || (raw_answer.is_a?(Array) && raw_answer.reject(&:blank?).empty?)
            errors << "Answer required for: #{question.question}"
            next
          end
        end

        answer_value = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)

        answer = question.loan_answers.find_or_initialize_by(user: current_user)
        answer.answer = answer_value
        answer.save!
      end

      raise ActiveRecord::Rollback unless errors.empty?
    end

    if errors.any?
      flash.now[:alert] = errors.join("<br>").html_safe
      @loan_answers = current_user.loan_answers.includes(:loan_question)
      @collections = Collection.joins(:collection_questions).distinct
      render :loan_questions, status: :unprocessable_entity
    else
      redirect_to profile_path, notice: "Loan questions updated successfully."
    end
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

    errors = []

    ActiveRecord::Base.transaction do
      @collection.collection_questions.each do |question|
        raw_answer = params[:collection_answers][question.id.to_s]

        if question.required?
          if raw_answer.blank? || (raw_answer.is_a?(Array) && raw_answer.reject(&:blank?).empty?)
            errors << "Answer required for: #{question.question}"
            next
          end
        end

        cleaned_answer = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)

        answer = current_user.collection_answers.find_or_initialize_by(collection_question: question)
        answer.answer = cleaned_answer
        answer.save!
      end

      raise ActiveRecord::Rollback unless errors.empty?
    end

    if errors.any?
      flash.now[:alert] = errors.join("<br>").html_safe
      @collection_questions = @collection.collection_questions
      @collection_answers = current_user.collection_answers.where(collection_question: @collection_questions)
      render :collection_questions, status: :unprocessable_entity
    else
      redirect_to profile_path, notice: "Your answers have been saved."
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :affiliation, :orcid)
  end
  
end

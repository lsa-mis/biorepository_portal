class LoanAnswersController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def edit
    @loan_question = LoanQuestion.find(params[:id])
    @answer = @loan_question.loan_answers.find_by(user: current_user)

    puts "⚠️ ENTERING edit action"
    puts "LoanQuestion ID: #{params[:id]}"
    puts "Question: #{@loan_question.question}"
    puts "Answer: #{@answer&.answer&.to_plain_text || 'No answer'}"

    render turbo_stream: turbo_stream.update("modal_content_frame") {
      render_to_string partial: "profiles/edit_single_loan_answer_form",
                      formats: [:html],
                      locals: { loan_question: @loan_question, existing_answer: @answer }
    }
  end

  def update
    question = LoanQuestion.find(params[:id])
    raw_answer = params[:loan_answers][question.id.to_s]

    if question.required?
      if raw_answer.blank? || (raw_answer.is_a?(Array) && raw_answer.reject(&:blank?).empty?)
        return redirect_back fallback_location: loan_request_path,
                             alert: "Answer required for: #{question.question}"
      end
    end

    answer_value = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)

    answer = question.loan_answers.find_or_initialize_by(user: current_user)
    answer.answer = answer_value

    if answer.save
      redirect_to loan_request_path, notice: "Answer updated successfully."
    else
      redirect_back fallback_location: loan_request_path,
                    alert: "Failed to update answer."
    end
  end
  
end

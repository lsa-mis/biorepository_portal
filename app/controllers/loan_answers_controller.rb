class LoanAnswersController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def edit
    @loan_question = LoanQuestion.find(params[:id])
    @answer = @loan_question.loan_answers.find_by(user: current_user)

    render turbo_stream: turbo_stream.update("modal_content_frame") {
      render_to_string partial: "profiles/edit_single_loan_answer_form",
                      formats: [:html],
                      locals: { loan_question: @loan_question, existing_answer: @answer }
    }
  end

  def update
    @question = LoanQuestion.find(params[:id])
    raw_answer = params[:loan_answers][@question.id.to_s]

    if @question.required?
      if raw_answer.blank? || (raw_answer.is_a?(Array) && raw_answer.reject(&:blank?).empty?)
        return respond_to do |format|
          format.html { redirect_back fallback_location: loan_request_path, alert: "Answer required for: #{@question.question}" }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Answer required for: #{@question.question}" }) }
        end
      end
    end

    answer_value = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)

    @answer = @question.loan_answers.find_or_initialize_by(user: current_user)
    @answer.answer = answer_value

    if @answer.save
      respond_to do |format|
        format.html { redirect_to loan_request_path, notice: "Answer updated successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: loan_request_path, alert: "Failed to update answer." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Failed to update answer." }) }
      end
    end
  end
end

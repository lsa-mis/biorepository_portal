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

    submitted_answers = params[:loan_answers] || {}
    raw_answer = submitted_answers[@question.id.to_s]

    @answer = @question.loan_answers.find_or_initialize_by(user: current_user)

    if @question.question_type == "attachments"
      if raw_answer.present? && raw_answer.is_a?(Array)
        raw_answer.each do |file|
          if file.is_a?(ActionDispatch::Http::UploadedFile)
            @answer.attachments.attach(file) # Attach the uploaded file
            @answer.answer = file.original_filename # Optionally store filename or info
          end
        end
      end
    else
      answer_value = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)
      @answer.answer = answer_value
    end

    if @answer.save
      respond_to do |format|
        format.html { redirect_to loan_request_path, notice: "Answer updated successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: loan_request_path, alert: "Failed to update answer." }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { alert: "Failed to update answer." }),
                status: :unprocessable_entity
        }
      end
    end
  end

  private

  def loan_answer_params
    params.require(:loan_answer).permit(:answer, :loan_question_id, :user_id, :attachment)
  end
end

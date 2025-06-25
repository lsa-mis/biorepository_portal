class Collections::CollectionAnswersController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  before_action :set_collection

  def edit
    @collection_question = CollectionQuestion.find(params[:id])
    @answer = @collection_question.collection_answers.find_by(user: current_user)
    render turbo_stream: turbo_stream.update("edit_collection_answer_modal_content_frame") {
      render_to_string partial: "profiles/edit_single_collection_answer_form",
                      formats: [:html],
                      locals: { collection: @collection, collection_question: @collection_question, existing_answer: @answer }
    }
  end

  def update
    @question = CollectionQuestion.find(params[:id])

    submitted_answers = params[:collection_answers] || {}
    raw_answer = submitted_answers[@question.id.to_s]

    answer_value = raw_answer.is_a?(Array) ? raw_answer.reject(&:blank?).join(", ") : strip_tags(raw_answer.to_s.strip)

    @answer = @question.collection_answers.find_or_initialize_by(user: current_user)
    @answer.answer = answer_value

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

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end
end

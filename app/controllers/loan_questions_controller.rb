class LoanQuestionsController < ApplicationController
  before_action :set_loan_question, only: %i[ show edit update destroy ]
  before_action :set_question_types, only: %i[ index new edit create update ]

  # GET /loan_questions or /loan_questions.json
  def index
    @loan_questions = LoanQuestion.all
    authorize @loan_questions
    @new_loan_question = LoanQuestion.new
  end

  # GET /loan_questions/1 or /loan_questions/1.json
  def show
    @options = @loan_question.options.order(:position)
  end

  # GET /loan_questions/new
  def new
    @loan_question = LoanQuestion.new
  end

  # GET /loan_questions/1/edit
  def edit
    @options = @loan_question.options.order(:position)
  end

  # POST /loan_questions or /loan_questions.json
  def create
    @loan_question = LoanQuestion.new(loan_question_params)
    if loan_question_params[:question_type] == "dropdown" || loan_question_params[:question_type] == "checkbox"
      options = params[:option_attributes].values
    end
    authorize @loan_question

    respond_to do |format|
      if @loan_question.save
        if loan_question_params[:question_type] == "dropdown" || loan_question_params[:question_type] == "checkbox" 
            options = params[:option_attributes].values        
            options.each do |option|
              Option.create(value: option[:value], loan_question_id: @loan_question.id)
            end
        end
        format.html { redirect_to @loan_question, notice: "Loan question was successfully created." }
        format.json { render :show, status: :ok, location: @loan_question }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @loan_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /loan_questions/1 or /loan_questions/1.json
  def update
    respond_to do |format|
      if @loan_question.update(loan_question_params)
        # If the question type supports options, update them
        if @loan_question.question_type.in?(%w[dropdown checkbox]) && params[:option_attributes].present?
          Rails.logger.info("Updating options for question: #{@loan_question.id}")
          Rails.logger.info("Params: #{params[:option_attributes].inspect}")

          params[:option_attributes].values.each_with_index do |option_param, index|
            if option_param[:id].present?
              option = @loan_question.options.find_by(id: option_param[:id])
              option&.update(value: option_param[:value], position: index)
            else
              @loan_question.options.create(value: option_param[:value], position: index)
            end
          end
        end
        format.html { redirect_to @loan_question, notice: "Loan question was successfully updated." }
        format.json { render :show, status: :ok, location: @loan_question }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @loan_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /loan_questions/1 or /loan_questions/1.json
  def destroy
    if @loan_question.destroy
      @loan_questions = LoanQuestion.all
      flash.now[:notice] = "Loan question was successfully deleted."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_loan_question
      @loan_question = LoanQuestion.find(params[:id])
    end

    def set_question_types
      @question_types = LoanQuestion.question_types.keys.map { |type| [ type.humanize, type ] }
    end

    # Only allow a list of trusted parameters through.
    def loan_question_params
      params.require(:loan_question).permit(
        :question,
        :question_type,
        options_attributes: [:id, :value, :_destroy]
      )
    end
end

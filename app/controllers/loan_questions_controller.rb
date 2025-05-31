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
    @options = @loan_question.options
  end

  # GET /loan_questions/new
  def new
    @loan_question = LoanQuestion.new
  end

  # GET /loan_questions/1/edit
  def edit
    @options = @loan_question.options
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
    authorize @loan_question
    transaction = ActiveRecord::Base.transaction do
      # raise ActiveRecord::Rollback unless 
      @loan_question.update(question: loan_question_params[:question])
        # If the question type supports options, update them
      if @loan_question.question_type.in?(%w[dropdown checkbox]) && params[:option_attributes].present?
        # raise ActiveRecord::Rollback unless 
        update_options(@loan_question, params[:option_attributes].values)          
      end
    end
    if transaction
      redirect_to @loan_question, notice: "Loan question was successfully updated."
    else
      render :edit, status: :unprocessable_entity
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

    def update_options(loan_question, option_attributes)
      if loan_question.options.present?
        Option.where(loan_question_id: loan_question.id).destroy_all
        option_attributes.each do |option|
          # raise ActiveRecord::Rollback unless 
          Option.create(value: option[:value], loan_question_id: loan_question.id)
        end
      end
      true
    end
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

class LoanQuestionsController < ApplicationController
  before_action :set_loan_question, only: %i[ show edit update destroy move_up move_down ]
  before_action :set_question_types, only: %i[ index new edit create update ]

  # GET /loan_questions or /loan_questions.json
  def index
    @loan_questions = LoanQuestion.order(:position)
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
    authorize @loan_question
  end

  # GET /loan_questions/1/edit
  def edit
    @options = @loan_question.options
  end

  # POST /loan_questions or /loan_questions.json
  def create
    @loan_question = LoanQuestion.new(loan_question_params)
    if loan_question_params[:question_type] == "dropdown" || loan_question_params[:question_type] == "checkbox"
      options = params[:options_attributes].values
    end

    respond_to do |format|
      if @loan_question.save
        if loan_question_params[:question_type] == "dropdown" || loan_question_params[:question_type] == "checkbox" 
            options = params[:options_attributes].values        
            options.each do |option|
              Option.create(value: option[:value], loan_question_id: @loan_question.id)
            end
        end
        format.html { redirect_to @loan_question, notice: "Loan question was successfully created." }
        format.json { render :show, status: :ok, location: @loan_question }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @loan_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /loan_questions/1 or /loan_questions/1.json
  def update
    success = true
    ActiveRecord::Base.transaction do
      begin
        @loan_question.update(loan_question_params)
        if @loan_question.question_type.in?(%w[dropdown checkbox]) && params[:options_attributes].present?
          update_options(@loan_question, params[:options_attributes].values)
        end
        success = true
      rescue StandardError => e
        raise ActiveRecord::Rollback
        flash.now[:alert] = "Error updating loan question with options: " + e.message
        success = false
      end
    end
    respond_to do |format|
      if success
        format.html { redirect_to @loan_question, notice: "Loan question was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
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

  # GET /loan_questions/preview
  def preview
    @loan_questions = LoanQuestion.all.order(:position)
    authorize @loan_questions
  end

  def move_up
    @loan_question.move_higher
    redirect_to loan_questions_path, notice: "Question moved up."
  end

  def move_down
    @loan_question.move_lower
    redirect_to loan_questions_path, notice: "Question moved down."
  end

  private

    def update_options(loan_question, options_attributes)
      if loan_question.options.present?
        Option.where(loan_question_id: loan_question.id).destroy_all
        options_attributes.each do |option|
          # raise ActiveRecord::Rollback unless 
          Option.create(value: option[:value], loan_question_id: loan_question.id)
        end
      end
      true
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_loan_question
      @loan_question = LoanQuestion.find(params[:id])
      authorize @loan_question
    end

    def set_question_types
      @question_types = LoanQuestion.question_types.keys.map { |type| [ type.humanize, type ] }
    end

    # Only allow a list of trusted parameters through.
    def loan_question_params
      params.require(:loan_question).permit(:position, :question, :question_type, :required, :options_attributes => [:id, :value])
    end
end


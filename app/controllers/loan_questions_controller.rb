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
  end

  # GET /loan_questions/new
  def new
    @loan_question = LoanQuestion.new
  end

  # GET /loan_questions/1/edit
  def edit
  end

  # POST /loan_questions or /loan_questions.json
  def create
    @loan_question = LoanQuestion.new(loan_question_params)
    authorize @loan_question

    # respond_to do |format|
    #   if @cloan_question.save
    #     notice = "Loan question was successfully created."
    #     format.turbo_stream do
    #       @new_cloan_question = LoanQuestion.new
    #       flash.now[:notice] = notice
    #     end
    #     format.html { redirect_to loan_questions_path, notice: notice }
    #   else
    #     format.html { render :new, status: :unprocessable_entity }
    #   end
    # end
    if @loan_question.save 
      flash.now[:notice] = "Loan question was successfully created."
      @new_loan_question = LoanQuestion.new
      @loan_questions = LoanQuestion.all
    else
      render :index, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /loan_questions/1 or /loan_questions/1.json
  def update
    respond_to do |format|
      if @loan_question.update(loan_question_params)
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
      @loan_question = LoanQuestion.find(params.expect(:id))
    end

    def set_question_types
      @question_types = LoanQuestion.question_types.keys.map { |type| [ type.humanize, type ] }
    end

    # Only allow a list of trusted parameters through.
    def loan_question_params
      params.expect(loan_question: [ :question, :question_type, options_attributes: [ :value ] ])
    end
end

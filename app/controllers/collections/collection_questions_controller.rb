class Collections::CollectionQuestionsController < ApplicationController
  before_action :set_collection
  before_action :set_collection_question, only: %i[ show edit update destroy move_up move_down ]
  before_action :set_question_types, only: %i[ new edit create update ]

  def index
    @collection_questions = @collection.collection_questions.order(:position)
    authorize([@collection, @collection_questions])
  end

  def show
  end
  
  def new
    @collection_question = @collection.collection_questions.build
    2.times { @collection_question.collection_options.build }
    authorize([@collection, @collection_question])
  end

  def create
    @collection_question = @collection.collection_questions.build(collection_question_params)
    authorize([@collection, @collection_question])

    respond_to do |format|
      begin
        if @collection_question.save
          if collection_question_params[:question_type].in?(%w[dropdown checkbox])
            options = params[:options_attributes].values
            options.each do |option|
              CollectionOption.create(value: option[:value], collection_question_id: @collection_question.id)
            end
          end
          format.html { redirect_to collection_collection_question_path(@collection, @collection_question), notice: "Collection question created." }
          format.json { render :show, status: :ok, location: [@collection, @collection_question] }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @collection_question.errors, status: :unprocessable_entity }
        end
      rescue => e
        @collection_question.errors.add(:base, "Unable to save: #{e.message}")
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @collection_question.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    2.times { @collection_question.collection_options.build } if @collection_question.collection_options.empty?
  end

  def update
    respond_to do |format|
      begin
        if @collection_question.update(collection_question_params)
          if @collection_question.question_type.in?(%w[dropdown checkbox]) && params[:options_attributes].present?
            update_options(@collection_question, params[:options_attributes].values)
          end
          format.html { redirect_to collection_collection_question_path(@collection, @collection_question), notice: "Collection question updated." }
          format.json { render :show, status: :ok, location: [@collection, @collection_question] }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @collection_question.errors, status: :unprocessable_entity }
        end
      rescue => e
        @collection_question.errors.add(:base, "Unable to save: #{e.message}")
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @collection_question.errors, status: :unprocessable_entity }
      end
    end
  end

  def preview
    @collection_questions = @collection.collection_questions.includes(:collection_options).order(:position)
    authorize([@collection, @collection_questions])
  end

  def move_up
    @collection_question.move_higher
    redirect_to collection_collection_questions_path, notice: "Question moved up."
  end

  def move_down
    @collection_question.move_lower
    redirect_to collection_collection_questions_path, notice: "Question moved down."
  end
  
  def destroy
    @collection_question.destroy

    respond_to do |format|
      @collection_questions = @collection.collection_questions.order(:position)
      format.turbo_stream
      format.html { redirect_to collection_path(@collection), notice: "Collection question deleted." }
    end
  end

  private

  def update_options(question, option_params)
    question.collection_options.destroy_all
    option_params.each do |option|
      CollectionOption.create(value: option[:value], collection_question_id: question.id)
    end
  end

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def set_collection_question
    @collection_question = @collection.collection_questions.find(params[:id])
    authorize([@collection, @collection_question])
  end

  def set_question_types
    @question_types = CollectionQuestion.question_types.keys.map { |t| [t.humanize, t] }
  end

  def collection_question_params
    params.require(:collection_question).permit(:question, :question_type, :required, :position, :collection_id,
      collection_options_attributes: [:id, :value])
  end
    
end

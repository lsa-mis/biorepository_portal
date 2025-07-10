class FaqsController < ApplicationController
  before_action :set_redirection_url
  before_action :set_faq, only: %i[ show edit update destroy move_up move_down]
  skip_before_action :authenticate_user!, only: %i[index]

  # GET /faqs or /faqs.json
  def index
    @faqs = Faq.all
  end

  # GET /faqs/1 or /faqs/1.json
  def show
  end

  # GET /faqs/new
  def new
    @faq = Faq.new
    authorize @faq
  end

  # GET /faqs/1/edit
  def edit
  end

  # POST /faqs or /faqs.json
  def create
    @faq = Faq.new(faq_params)
    authorize @faq

    respond_to do |format|
      if @faq.save
        format.html { redirect_to faqs_path, notice: "FAQ was successfully created." }
        format.json { render :show, status: :created, location: @faq }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @faq.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /faqs/1 or /faqs/1.json
  def update
    respond_to do |format|
      if @faq.update(faq_params)
        format.html { redirect_to faqs_path, notice: "FAQ was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /faqs/1 or /faqs/1.json
  def destroy
    @faq.destroy!

    respond_to do |format|
      format.html { redirect_to faqs_path, status: :see_other, notice: "FAQ was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def reorder
    @faqs = Faq.order(:position)
    authorize @faqs
  end

  def move_up
    @faq.move_higher
    redirect_to reorder_faq_path, notice: "Question moved up."
  end

  def move_down
    @faq.move_lower
    redirect_to reorder_faq_path, notice: "Question moved down."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_faq
      @faq = Faq.find(params[:id])
      authorize @faq
    end

    # Only allow a list of trusted parameters through.
    def faq_params
      params.require(:faq).permit(:question, :answer, :position)
    end
end

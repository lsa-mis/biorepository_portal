class PreparationsController < ApplicationController
  before_action :set_preparation, only: %i[ show edit update destroy ]

  # GET /preparations or /preparations.json
  def index
    @preparations = Preparation.all
  end

  # GET /preparations/1 or /preparations/1.json
  def show
  end

  # GET /preparations/new
  def new
    @preparation = Preparation.new
  end

  # GET /preparations/1/edit
  def edit
  end

  # POST /preparations or /preparations.json
  def create
    @preparation = Preparation.new(preparation_params)

    respond_to do |format|
      if @preparation.save
        format.html { redirect_to @preparation, notice: "Preparation was successfully created." }
        format.json { render :show, status: :created, location: @preparation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @preparation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /preparations/1 or /preparations/1.json
  def update
    respond_to do |format|
      if @preparation.update(preparation_params)
        format.html { redirect_to @preparation, notice: "Preparation was successfully updated." }
        format.json { render :show, status: :ok, location: @preparation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @preparation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /preparations/1 or /preparations/1.json
  def destroy
    @preparation.destroy!

    respond_to do |format|
      format.html { redirect_to preparations_path, status: :see_other, notice: "Preparation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_preparation
      @preparation = Preparation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def preparation_params
      params.expect(preparation: [ :prep_type, :count, :barcode, :description, :item_id ])
    end
end

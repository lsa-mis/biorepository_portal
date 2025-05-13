class IdentificationsController < ApplicationController
  before_action :set_identification, only: %i[ show edit update destroy ]

  # GET /identifications or /identifications.json
  def index
    @identifications = Identification.all
  end

  # GET /identifications/1 or /identifications/1.json
  def show
  end

  # GET /identifications/new
  def new
    @identification = Identification.new
  end

  # GET /identifications/1/edit
  def edit
  end

  # POST /identifications or /identifications.json
  def create
    @identification = Identification.new(identification_params)

    respond_to do |format|
      if @identification.save
        format.html { redirect_to @identification, notice: "Identification was successfully created." }
        format.json { render :show, status: :created, location: @identification }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @identification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /identifications/1 or /identifications/1.json
  def update
    respond_to do |format|
      if @identification.update(identification_params)
        format.html { redirect_to @identification, notice: "Identification was successfully updated." }
        format.json { render :show, status: :ok, location: @identification }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @identification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /identifications/1 or /identifications/1.json
  def destroy
    @identification.destroy!

    respond_to do |format|
      format.html { redirect_to identifications_path, status: :see_other, notice: "Identification was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_identification
      @identification = Identification.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def identification_params
      params.expect(identification: [ :type_status, :identified_by, :date_identified, :identification_remarks, :scientific_name, :scientific_name_authorship, :kingdom, :phylum, :class_name, :order_name, :family, :genus, :specific_epithet, :infraspecific_epithet, :taxon_rank, :vernacular_name, :item_id ])
    end
end

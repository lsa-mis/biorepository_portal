class AddressesController < ApplicationController
  before_action :set_address, only: [:edit, :update, :destroy]

  def index
    @addresses = current_user.addresses.order(primary: :desc, created_at: :asc)
  end

  def new
    @address = current_user.addresses.new
  end

  def create
    @address = current_user.addresses.new(address_params)
    if @address.save
      if params[:loan_request] == "true"
        redirect_to step_five_path, notice: "New Address Added"
      else
        redirect_to addresses_path, notice: "Address saved."
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      if params[:loan_request] == "true"
        redirect_to step_five_path, notice: "Address Updated"
      else
        redirect_to addresses_path, notice: "Address updated."
      end
    else
      render :edit
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_path, notice: "Address deleted."
  end

  private

  def set_address
    @address = current_user.addresses.find_by(id: params[:id])
    redirect_to addresses_path, alert: "Address not found." unless @address
  end

  def address_params
    params.require(:address).permit(:first_name, :last_name, :email, :address_line_1, :address_line_2, :city, :state, :zip, :country_code, :phone, :primary)
  end
end

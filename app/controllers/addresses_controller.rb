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
      redirect_to addresses_path, notice: "Address saved."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @address.update(address_params)
      redirect_to addresses_path, notice: "Address updated."
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
    params.require(:address).permit(:first_name, :last_name, :email, :street, :city, :state, :zip, :country, :phone, :primary)
  end
end

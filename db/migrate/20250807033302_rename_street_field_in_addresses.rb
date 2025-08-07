class RenameStreetFieldInAddresses < ActiveRecord::Migration[8.0]
  def change
    rename_column :addresses, :street, :address_line_1
  end
end

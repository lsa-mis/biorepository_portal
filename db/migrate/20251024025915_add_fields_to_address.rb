class AddFieldsToAddress < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :address_line_3, :string
    add_column :addresses, :address_line_4, :string
  end
end

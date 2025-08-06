class AddEmailAndLine2ToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :email, :string
    add_column :addresses, :address_line_2, :string
  end
end

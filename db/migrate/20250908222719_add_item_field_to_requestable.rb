class AddItemFieldToRequestable < ActiveRecord::Migration[8.0]
  def change
    add_column :requestables, :item_name, :string
    add_column :requestables, :collection, :string
  end
end

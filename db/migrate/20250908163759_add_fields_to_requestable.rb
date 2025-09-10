class AddFieldsToRequestable < ActiveRecord::Migration[8.0]
  def change
    add_reference :requestables, :item, null: true, foreign_key: true
    add_column :requestables, :preparation_type, :string
  end
end

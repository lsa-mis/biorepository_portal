class EditItemForeignKeyInRequestables < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :requestables, :items
    add_foreign_key :requestables, :items, column: :item_id, on_delete: :cascade
  end
end

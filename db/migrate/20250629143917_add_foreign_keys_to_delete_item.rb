class AddForeignKeysToDeleteItem < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :identifications, :items
    add_foreign_key :identifications, :items, column: :item_id, on_delete: :cascade
    remove_foreign_key :preparations, :items
    add_foreign_key :preparations, :items, column: :item_id, on_delete: :cascade 
  end
end

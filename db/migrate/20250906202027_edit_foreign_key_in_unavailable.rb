class EditForeignKeyInUnavailable < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :unavailables, :items
    add_foreign_key :unavailables, :items, column: :item_id, on_delete: :cascade
  end
end

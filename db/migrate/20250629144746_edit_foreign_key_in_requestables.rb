class EditForeignKeyInRequestables < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :requestables, :preparations
    add_foreign_key :requestables, :preparations, column: :preparation_id, on_delete: :cascade
  end
end

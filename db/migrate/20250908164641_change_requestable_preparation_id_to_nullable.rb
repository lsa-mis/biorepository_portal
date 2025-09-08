class ChangeRequestablePreparationIdToNullable < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing foreign key constraint
    remove_foreign_key :requestables, :preparations
    
    # Change the column to allow null values
    change_column_null :requestables, :preparation_id, true
    
    # Add the foreign key constraint back with ON DELETE SET NULL
    add_foreign_key :requestables, :preparations, on_delete: :nullify
  end
end

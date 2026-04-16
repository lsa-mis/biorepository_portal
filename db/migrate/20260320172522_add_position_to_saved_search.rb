class AddPositionToSavedSearch < ActiveRecord::Migration[8.1]
  def change
    add_column :saved_searches, :position, :integer
    add_index :saved_searches, :position
  end
end

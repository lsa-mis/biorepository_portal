class RemoveDisplayNameFromUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :display_name
  end
end

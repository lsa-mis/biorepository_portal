class RemovePositionFromOptions < ActiveRecord::Migration[8.0]
  def change
    remove_column :options, :position
  end
end

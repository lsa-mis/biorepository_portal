class AddPositionToOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :options, :position, :integer
  end
end

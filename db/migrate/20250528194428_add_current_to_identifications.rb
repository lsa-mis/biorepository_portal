class AddCurrentToIdentifications < ActiveRecord::Migration[8.0]
  def change
    add_column :identifications, :current, :boolean, null: false, default: false
  end
end

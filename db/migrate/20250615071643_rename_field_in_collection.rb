class RenameFieldInCollection < ActiveRecord::Migration[8.0]
  def change
    rename_column :collections, :description, :short_description
  end
end

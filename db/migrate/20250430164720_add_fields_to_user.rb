class AddFieldsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :principal_name, :string
    add_column :users, :display_name, :string
    add_column :users, :person_affiliation, :string
  end
end

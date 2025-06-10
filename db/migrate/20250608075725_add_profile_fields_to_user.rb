class AddProfileFieldsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :orcid, :string
    rename_column :users, :person_affiliation, :affiliation
  end
end

class UpdateItemsAndIdentificationsSchema < ActiveRecord::Migration[6.1]
  def change
    # Remove 'archived' column from items
    remove_column :items, :archived, :boolean

    # Change taxon_rank from integer to string
    change_column :identifications, :taxon_rank, :string
  end
end

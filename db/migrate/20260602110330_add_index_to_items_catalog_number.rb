class AddIndexToItemsCatalogNumber < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :items, :catalog_number, algorithm: :concurrently
  end
end

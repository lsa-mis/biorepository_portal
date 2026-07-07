class ReconcileItemsCollectionFilterIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :items, [:collection_id, :continent], name: "idx_items_collection_continent", algorithm: :concurrently, if_not_exists: true
    add_index :items, [:collection_id, :country], name: "idx_items_collection_country", algorithm: :concurrently, if_not_exists: true
    add_index :items, [:collection_id, :sex], name: "idx_items_collection_sex", algorithm: :concurrently, if_not_exists: true
    add_index :items, [:collection_id, :state_province], name: "idx_items_collection_state_province", algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :items, name: "idx_items_collection_continent", algorithm: :concurrently, if_exists: true
    remove_index :items, name: "idx_items_collection_country", algorithm: :concurrently, if_exists: true
    remove_index :items, name: "idx_items_collection_sex", algorithm: :concurrently, if_exists: true
    remove_index :items, name: "idx_items_collection_state_province", algorithm: :concurrently, if_exists: true
  end
end
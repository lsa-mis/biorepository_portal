class AddCollectionIdsToRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :information_requests, :collection_ids, :integer, array: true, default: []
    add_column :loan_requests, :collection_ids, :integer, array: true, default: []
    add_index :information_requests, :collection_ids, using: 'gin'
    add_index :loan_requests, :collection_ids, using: 'gin'
  end
end

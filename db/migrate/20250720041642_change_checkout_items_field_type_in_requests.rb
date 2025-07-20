class ChangeCheckoutItemsFieldTypeInRequests < ActiveRecord::Migration[8.0]
  def change
    remove_column :loan_requests, :checkout_items
    add_column :loan_requests, :checkout_items, :string, array: true, default: []
    add_index :loan_requests, :checkout_items, using: 'gin'
  end
end

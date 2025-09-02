class ChangeCheckoutItemsFieldTypeInInformationRequests < ActiveRecord::Migration[8.0]
  def change
    remove_column :information_requests, :checkout_items
    add_column :information_requests, :checkout_items, :string, array: true, default: []
    add_index :information_requests, :checkout_items, using: 'gin'
  end
end

class AddUserIdToCheckout < ActiveRecord::Migration[8.0]
  def change
    add_reference :checkouts, :user, null: true, foreign_key: true
  end
end

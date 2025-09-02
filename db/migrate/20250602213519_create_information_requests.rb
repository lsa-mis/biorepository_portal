class CreateInformationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :information_requests do |t|
      t.string :send_to
      t.string :checkout_items
      t.belongs_to :user, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end

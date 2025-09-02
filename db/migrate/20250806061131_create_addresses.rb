class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :phone
      t.boolean :primary

      t.timestamps
    end
  end
end

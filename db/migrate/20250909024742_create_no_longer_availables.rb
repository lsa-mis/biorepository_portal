class CreateNoLongerAvailables < ActiveRecord::Migration[8.0]
  def change
    create_table :no_longer_availables do |t|
      t.belongs_to :checkout, null: false, foreign_key: true
      t.string :preparation_type
      t.string :item_name
      t.string :collection
      
      t.timestamps
    end
  end
end

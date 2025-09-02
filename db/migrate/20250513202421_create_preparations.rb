class CreatePreparations < ActiveRecord::Migration[8.0]
  def change
    create_table :preparations do |t|
      t.string :prep_type
      t.integer :count
      t.string :barcode
      t.string :description
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end
  end
end

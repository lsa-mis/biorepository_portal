class CreateUnavalables < ActiveRecord::Migration[8.0]
  def change
    create_table :unavalables do |t|
      t.belongs_to :item, null: false, foreign_key: true
      t.belongs_to :checkout, null: false, foreign_key: true
      t.string :preparation_type

      t.timestamps
    end
  end
end

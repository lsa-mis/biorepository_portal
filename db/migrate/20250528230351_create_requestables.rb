class CreateRequestables < ActiveRecord::Migration[8.0]
  def change
    create_table :requestables do |t|
      t.belongs_to :preparation, null: false, foreign_key: true
      t.belongs_to :checkout, null: false, foreign_key: true
      t.integer :count

      t.timestamps
    end
  end
end

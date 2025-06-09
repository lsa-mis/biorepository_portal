class CreateCollectionOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_options do |t|
      t.string :value, null: false
      t.references :collection_question, null: false, foreign_key: true

      t.timestamps
    end
  end
end

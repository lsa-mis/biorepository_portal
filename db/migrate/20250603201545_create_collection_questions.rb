class CreateCollectionQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_questions do |t|
      t.references :collection, null: false, foreign_key: true
      t.string :question, null: false
      t.boolean :required, default: false

      t.timestamps
    end
  end
end

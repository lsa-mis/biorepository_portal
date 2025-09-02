class CreateCollectionAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection_question, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class DropCollectionAnswers < ActiveRecord::Migration[7.0]
  def change
    drop_table :collection_answers
  end
end

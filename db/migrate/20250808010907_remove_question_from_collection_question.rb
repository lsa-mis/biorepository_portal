class RemoveQuestionFromCollectionQuestion < ActiveRecord::Migration[8.0]
  def change
    remove_column :collection_questions, :question
  end
end

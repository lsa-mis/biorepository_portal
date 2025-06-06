class AddQuestionTypeToCollectionQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_questions, :question_type, :integer
  end
end

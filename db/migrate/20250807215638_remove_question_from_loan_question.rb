class RemoveQuestionFromLoanQuestion < ActiveRecord::Migration[8.0]
  def change
    remove_column :loan_questions, :question
  end
end

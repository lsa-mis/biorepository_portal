class AddPositionToLoanQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_questions, :position, :integer
    add_index :loan_questions, :position
  end
end

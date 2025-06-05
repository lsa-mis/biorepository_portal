class AddRequiredToLoanQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_questions, :required, :boolean, default: false, null: false
  end
end

class CreateLoanQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_questions do |t|
      t.string :question
      t.integer :question_type

      t.timestamps
    end
  end
end

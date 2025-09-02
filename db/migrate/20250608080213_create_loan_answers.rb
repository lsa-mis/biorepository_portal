class CreateLoanAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_answers do |t|

      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :loan_question, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end

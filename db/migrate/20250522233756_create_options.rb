class CreateOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :options do |t|
      t.timestamps
      t.string :value

      t.references :loan_question, null: false, foreign_key: true
    end
  end
end

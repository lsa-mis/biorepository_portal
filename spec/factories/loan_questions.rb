# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  question      :string
#  question_type :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :loan_question do
    question { "MyString" }
    question_type { 1 }
  end
end

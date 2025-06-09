# == Schema Information
#
# Table name: loan_answers
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  loan_question_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_loan_answers_on_loan_question_id  (loan_question_id)
#  index_loan_answers_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (loan_question_id => loan_questions.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :loan_answer do
    
  end
end

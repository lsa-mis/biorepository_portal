# == Schema Information
#
# Table name: options
#
#  id               :bigint           not null, primary key
#  value            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  loan_question_id :bigint           not null
#
# Indexes
#
#  index_options_on_loan_question_id  (loan_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (loan_question_id => loan_questions.id)
#
class Option < ApplicationRecord
  belongs_to :loan_question

  validates :value, presence: true

end

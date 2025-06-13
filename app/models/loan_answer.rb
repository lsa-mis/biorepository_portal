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
class LoanAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :loan_question
  has_rich_text :answer
  has_one_attached :attachment
  validates :response_file_presence_for_attachment

  private
  
  def response_file_presence_for_attachment
    if loan_question.question_type_attachment? && loan_question.required? && !attachment.attached?
      errors.add(:attachment, "must be present for attachment type question")
    end
  end

end

# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  position      :integer
#  question_type :integer
#  required      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_loan_questions_on_position  (position)
#
class LoanQuestion < ApplicationRecord
  acts_as_list
  has_many :options, dependent: :destroy
  has_many :loan_answers, dependent: :destroy
  has_rich_text :question
  accepts_nested_attributes_for :options, allow_destroy: true
  enum :question_type, [:text, :dropdown, :checkbox, :attachments], prefix: true

  validates_presence_of :question, message: "can't be blank"
  validate :question_content_uniqueness
  validates :question_type, presence: true

  def question_content_uniqueness
    return unless question.present?
    
    # Get the plain text content of the rich text for comparison
    question_text = question.to_plain_text.strip
    
    # Skip validation if the question content is empty
    return if question_text.blank?
    
    # Check if another loan question has the same content (excluding current record)
    duplicate_exists = LoanQuestion.joins(:rich_text_question)
                                   .where.not(id: id)
                                   .where(action_text_rich_texts: { body: question.body })
                                   .exists?
    if duplicate_exists
      errors.add(:question, 'has already been taken')
    end
  end

end


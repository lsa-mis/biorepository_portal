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
  enum :question_type, [:text, :dropdown, :checkbox, :attachment], prefix: true

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
    existing_question = LoanQuestion.joins(:rich_text_question)
                                   .where.not(id: id)
                                   .find_each do |loan_question|
      if loan_question.question.to_plain_text.strip == question_text
        errors.add(:question, 'has already been taken')
        break
      end
    end
  end

end


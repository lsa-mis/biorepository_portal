# == Schema Information
#
# Table name: collection_questions
#
#  id            :bigint           not null, primary key
#  position      :integer
#  question_type :integer
#  required      :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :bigint           not null
#
# Indexes
#
#  index_collection_questions_on_collection_id  (collection_id)
#  index_collection_questions_on_position       (position)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class CollectionQuestion < ApplicationRecord
  belongs_to :collection
  acts_as_list scope: :collection
  has_many :collection_options, dependent: :destroy
  has_many :collection_answers, dependent: :destroy
  has_rich_text :question

  accepts_nested_attributes_for :collection_options, allow_destroy: true

  enum :question_type, [:text, :dropdown, :checkbox, :attachments], prefix: true
  validates_presence_of :question, message: "can't be blank"
  validate :question_content_uniqueness_in_collection
  validates :question_type, presence: true

  def question_content_uniqueness_in_collection
    return unless question.present? && collection_id.present?
    
    # Get the plain text content of the rich text for comparison
    question_text = question.to_plain_text.strip
    
    # Skip validation if the question content is empty
    return if question_text.blank?
    
    # Check if another collection question in the same collection has the same content (excluding current record)
    duplicate_exists = CollectionQuestion.joins(:rich_text_question)
      .where(collection_id: collection_id)
      .where.not(id: id)
      .where(action_text_rich_texts: { body: question.body })
      .exists?
    if duplicate_exists
      errors.add(:question, 'has already been taken within this collection')
    end
  end
  
end

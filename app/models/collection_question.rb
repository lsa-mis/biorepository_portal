# == Schema Information
#
# Table name: collection_questions
#
#  id            :bigint           not null, primary key
#  position      :integer
#  question      :string           not null
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

  accepts_nested_attributes_for :collection_options, allow_destroy: true

  enum :question_type, [:text, :dropdown, :checkbox, :attachment], prefix: true
  validates :question, presence: true
  validates :question, uniqueness: { scope: :collection_id, message: "must be unique within the collection" }
  validates :question_type, presence: true
end

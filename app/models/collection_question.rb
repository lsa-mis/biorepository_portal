# == Schema Information
#
# Table name: collection_questions
#
#  id            :bigint           not null, primary key
#  question      :string           not null
#  required      :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :bigint           not null
#
# Indexes
#
#  index_collection_questions_on_collection_id  (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class CollectionQuestion < ApplicationRecord
  belongs_to :collection
  has_many :collection_answers, dependent: :destroy
end

# == Schema Information
#
# Table name: collection_questions
#
#  id            :bigint           not null, primary key
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
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
FactoryBot.define do
  factory :collection_question do
    question { "Affiliation" }
    question_type { :text }
    required { false }
    association :collection
  end
end

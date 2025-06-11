# == Schema Information
#
# Table name: collection_answers
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  collection_question_id :bigint           not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_collection_answers_on_collection_question_id  (collection_question_id)
#  index_collection_answers_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_question_id => collection_questions.id)
#  fk_rails_...  (user_id => users.id)
#
class CollectionAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :collection_question
  has_rich_text :answer
end

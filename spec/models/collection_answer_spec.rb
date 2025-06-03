# == Schema Information
#
# Table name: collection_answers
#
#  id                     :bigint           not null, primary key
#  answer                 :text
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
require 'rails_helper'

RSpec.describe CollectionAnswer, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

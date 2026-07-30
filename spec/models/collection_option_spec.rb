# == Schema Information
#
# Table name: collection_options
#
#  id                     :bigint           not null, primary key
#  value                  :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  collection_question_id :bigint           not null
#
# Indexes
#
#  index_collection_options_on_collection_question_id  (collection_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_question_id => collection_questions.id)
#
require 'rails_helper'

RSpec.describe CollectionOption, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

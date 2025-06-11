# == Schema Information
#
# Table name: options
#
#  id               :bigint           not null, primary key
#  position         :integer
#  value            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  loan_question_id :bigint           not null
#
# Indexes
#
#  index_options_on_loan_question_id  (loan_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (loan_question_id => loan_questions.id)
#
require 'rails_helper'

RSpec.describe Option, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

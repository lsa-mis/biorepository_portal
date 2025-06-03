# == Schema Information
#
# Table name: information_requests
#
#  id             :bigint           not null, primary key
#  checkout_items :string
#  send_to        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_information_requests_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe InformationRequest, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

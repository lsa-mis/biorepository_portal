# == Schema Information
#
# Table name: addresses
#
#  id             :bigint           not null, primary key
#  address_line_1 :string
#  address_line_2 :string
#  city           :string
#  country_code   :string
#  email          :string
#  first_name     :string
#  last_name      :string
#  phone          :string
#  primary        :boolean
#  state          :string
#  zip            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_addresses_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Address, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

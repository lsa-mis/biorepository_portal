# == Schema Information
#
# Table name: addresses
#
#  id             :bigint           not null, primary key
#  address_line_2 :string
#  city           :string
#  country        :string
#  email          :string
#  first_name     :string
#  last_name      :string
#  phone          :string
#  primary        :boolean
#  state          :string
#  street         :string
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
FactoryBot.define do
  factory :address do
    user { nil }
    first_name { "MyString" }
    last_name { "MyString" }
    street { "MyString" }
    city { "MyString" }
    state { "MyString" }
    zip { "MyString" }
    country { "MyString" }
    phone { "MyString" }
    primary { false }
  end
end

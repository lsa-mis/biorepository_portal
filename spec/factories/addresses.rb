# == Schema Information
#
# Table name: addresses
#
#  id             :bigint           not null, primary key
#  address_line_1 :string
#  address_line_2 :string
#  address_line_3 :string
#  address_line_4 :string
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
FactoryBot.define do
  factory :address do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    address_line_1 { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip_code }
    country_code { "US" }
    phone { Faker::PhoneNumber.phone_number }
    primary { false }
  end
end

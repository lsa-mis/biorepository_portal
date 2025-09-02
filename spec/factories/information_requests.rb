# == Schema Information
#
# Table name: information_requests
#
#  id             :bigint           not null, primary key
#  checkout_items :string           default([]), is an Array
#  collection_ids :integer          default([]), is an Array
#  send_to        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_information_requests_on_checkout_items  (checkout_items) USING gin
#  index_information_requests_on_collection_ids  (collection_ids) USING gin
#  index_information_requests_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :information_request do
    send_to { "MyString" }
    checkout_items { "MyString" }
    association :user
  end
end

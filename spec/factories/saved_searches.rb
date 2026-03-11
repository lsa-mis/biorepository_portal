# == Schema Information
#
# Table name: saved_searches
#
#  id            :bigint           not null, primary key
#  filters       :jsonb
#  global        :boolean          default(FALSE)
#  name          :string
#  search_params :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_saved_searches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :saved_search do
    user { nil }
    name { "MyString" }
    search_params { "" }
  end
end

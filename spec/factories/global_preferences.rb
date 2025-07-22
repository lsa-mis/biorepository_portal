# == Schema Information
#
# Table name: global_preferences
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  pref_type   :integer
#  value       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :global_preference do
    name { "Default Name" }
    description { "Default Description" }
    pref_type { 1 }
    value { "Default Value" }
  end
end

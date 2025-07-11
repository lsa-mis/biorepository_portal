# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  displayed  :boolean
#  location   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :announcement do
    location { "MyString" }
  end
end

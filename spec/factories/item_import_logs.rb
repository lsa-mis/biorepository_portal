# == Schema Information
#
# Table name: item_import_logs
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  note          :string           default([]), is an Array
#  status        :string
#  user          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer
#
FactoryBot.define do
  factory :item_import_log do
    date { "2025-07-25 09:34:51" }
    user_uniqname { "MyString" }
    status { "MyString" }
    note { "MyString" }
  end
end

# == Schema Information
#
# Table name: preparations
#
#  id          :bigint           not null, primary key
#  barcode     :string
#  count       :integer
#  description :string
#  prep_type   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  item_id     :bigint           not null
#
# Indexes
#
#  index_preparations_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :preparation do
    prep_type { "MyString" }
    count { 4 }
    barcode { "MyString" }
    description { "MyString" }
    item { nil }
  end
end

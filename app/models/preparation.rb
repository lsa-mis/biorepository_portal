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
#  fk_rails_...  (item_id => items.id)
#
class Preparation < ApplicationRecord
  belongs_to :item
  has_many :requestables
  has_many :checkouts, through: :requestables
end

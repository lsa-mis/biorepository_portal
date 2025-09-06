# == Schema Information
#
# Table name: unavalables
#
#  id               :bigint           not null, primary key
#  preparation_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  checkout_id      :bigint           not null
#  item_id          :bigint           not null
#
# Indexes
#
#  index_unavalables_on_checkout_id  (checkout_id)
#  index_unavalables_on_item_id      (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#  fk_rails_...  (item_id => items.id)
#
class Unavalable < ApplicationRecord
  belongs_to :item
  belongs_to :checkout
end

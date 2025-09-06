# == Schema Information
#
# Table name: unavailables
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
#  index_unavailables_on_checkout_id  (checkout_id)
#  index_unavailables_on_item_id      (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#  fk_rails_...  (item_id => items.id)
#
require 'rails_helper'

RSpec.describe Unavailable, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

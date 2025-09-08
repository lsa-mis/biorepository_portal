# == Schema Information
#
# Table name: requestables
#
#  id               :bigint           not null, primary key
#  count            :integer
#  preparation_type :string
#  saved_for_later  :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  checkout_id      :bigint           not null
#  item_id          :bigint
#  preparation_id   :bigint
#
# Indexes
#
#  index_requestables_on_checkout_id     (checkout_id)
#  index_requestables_on_item_id         (item_id)
#  index_requestables_on_preparation_id  (preparation_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#  fk_rails_...  (item_id => items.id) ON DELETE => cascade
#  fk_rails_...  (preparation_id => preparations.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :requestable do
    preparation_id { nil }
    checkout_id { nil }
    count { 1 }
    saved_for_later { false }
  end
end

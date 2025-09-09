# == Schema Information
#
# Table name: requestables
#
#  id               :bigint           not null, primary key
#  collection       :string
#  count            :integer
#  item_name        :string
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
#  fk_rails_...                   (checkout_id => checkouts.id)
#  fk_rails_...                   (preparation_id => preparations.id) ON DELETE => nullify
#  fk_rails_requestables_item_id  (item_id => items.id) ON DELETE => nullify
#
class Requestable < ApplicationRecord
  belongs_to :preparation, optional: true
  belongs_to :item, optional: true
  belongs_to :checkout

  scope :saved_for_later, -> { where(saved_for_later: true) }
  scope :active, -> { where(saved_for_later: false) }

end

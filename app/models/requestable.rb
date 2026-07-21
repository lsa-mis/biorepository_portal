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
  scope :active, -> {
    joins(item: :collection)
      .where(saved_for_later: false, collections: { no_loan_requests: false })
      .where.not(preparation_id: nil)
      .where.not(item_id: nil)
  }
  scope :active_in_checkout, -> { where(saved_for_later: false).where.not(preparation_id: nil).where.not(item_id: nil) }
  scope :available_for_checkout, -> { active.joins(:preparation).where("preparations.count > 0") }

  def active?
    return false if saved_for_later

    preparation_id.present? && item_id.present? && !item&.collection&.no_loan_requests?
  end

  def active_in_checkout?
    return false if saved_for_later

    preparation_id.present? && item_id.present?
  end

end

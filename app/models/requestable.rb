# == Schema Information
#
# Table name: requestables
#
#  id              :bigint           not null, primary key
#  count           :integer
#  saved_for_later :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  checkout_id     :bigint           not null
#  preparation_id  :bigint           not null
#
# Indexes
#
#  index_requestables_on_checkout_id     (checkout_id)
#  index_requestables_on_preparation_id  (preparation_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#  fk_rails_...  (preparation_id => preparations.id) ON DELETE => cascade
#
class Requestable < ApplicationRecord
  belongs_to :preparation
  belongs_to :checkout

  scope :saved_for_later, -> { where(saved_for_later: true) }
  scope :active, -> { where(saved_for_later: false) }
  scope :available, -> { active.joins(:preparation).where('preparations.count > 0') }

end

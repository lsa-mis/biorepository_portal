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
FactoryBot.define do
  factory :requestable do
    preparation_id { nil }
    checkout_id { nil }
    count { 1 }
    saved_for_later { false }
  end
end

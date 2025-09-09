# == Schema Information
#
# Table name: no_longer_availables
#
#  id               :bigint           not null, primary key
#  collection       :string
#  item_name        :string
#  preparation_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  checkout_id      :bigint           not null
#
# Indexes
#
#  index_no_longer_availables_on_checkout_id  (checkout_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#
FactoryBot.define do
  factory :no_longer_available do
    
  end
end

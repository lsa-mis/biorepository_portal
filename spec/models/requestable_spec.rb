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
require 'rails_helper'

RSpec.describe Requestable, type: :model do
  describe '.active' do
    let(:checkout) { FactoryBot.create(:checkout) }

    it 'includes requestables from collections that allow loan requests' do
      collection = FactoryBot.create(:collection, no_loan_requests: false)
      item = FactoryBot.create(:item, collection: collection)
      preparation = FactoryBot.create(:preparation, item: item)
      requestable = FactoryBot.create(:requestable, checkout: checkout, preparation: preparation, item_id: item.id)

      expect(described_class.active).to include(requestable)
    end

    it 'excludes requestables from information request only collections' do
      collection = FactoryBot.create(:collection, no_loan_requests: true)
      item = FactoryBot.create(:item, collection: collection)
      preparation = FactoryBot.create(:preparation, item: item)
      requestable = FactoryBot.create(:requestable, checkout: checkout, preparation: preparation, item_id: item.id)

      expect(described_class.active).not_to include(requestable)
      expect(requestable).not_to be_active
    end
  end

  describe '.active_in_checkout' do
    let(:checkout) { FactoryBot.create(:checkout) }

    it 'includes requestables from information request only collections' do
      collection = FactoryBot.create(:collection, no_loan_requests: true)
      item = FactoryBot.create(:item, collection: collection)
      preparation = FactoryBot.create(:preparation, item: item)
      requestable = FactoryBot.create(:requestable, checkout: checkout, preparation: preparation, item_id: item.id)

      expect(described_class.active_in_checkout).to include(requestable)
      expect(requestable).to be_active_in_checkout
    end
  end

  describe '.available_in_cart' do
    let(:checkout) { FactoryBot.create(:checkout) }

    it 'includes available requestables from information request only collections' do
      collection = FactoryBot.create(:collection, no_loan_requests: true)
      item = FactoryBot.create(:item, collection: collection)
      preparation = FactoryBot.create(:preparation, item: item, count: 2)
      requestable = FactoryBot.create(:requestable, checkout: checkout, preparation: preparation, item_id: item.id)

      expect(described_class.available_in_cart).to include(requestable)
    end
  end

end

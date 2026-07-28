require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#preparation_checkout_label' do
    it 'returns the standard checkout label for loan request collections' do
      collection = build(:collection, no_loan_requests: false)
      item = build(:item, collection: collection)

      expect(helper.preparation_checkout_label(item)).to eq('Add Preparation to Checkout')
    end

    it 'returns the information-only checkout label for no loan request collections' do
      collection = build(:collection, no_loan_requests: true)
      item = build(:item, collection: collection)

      expect(helper.preparation_checkout_label(item)).to eq('Add Preparation to Checkout (Information Request Only)')
    end
  end
end

# == Schema Information
#
# Table name: collections
#
#  id                :bigint           not null, primary key
#  admin_group       :string
#  division          :string
#  division_page_url :string
#  link_to_policies  :string
#  short_description :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_collections_on_division  (division)
#
require 'rails_helper'

RSpec.describe Collection, type: :model do
  describe '#no_loan_requests' do
    let(:collection) { create(:collection) }

    it 'is false when the preference is not enabled' do
      create(
        :app_preference,
        collection: collection,
        name: 'no_loan_requests',
        pref_type: :boolean,
        value: '0'
      )

      expect(collection.no_loan_requests).to be false
    end

    it 'is true when the collection-specific preference is enabled' do
      create(
        :app_preference,
        collection: collection,
        name: 'no_loan_requests',
        pref_type: :boolean,
        value: '1'
      )

      expect(collection.no_loan_requests).to be true
    end
  end
end

# == Schema Information
#
# Table name: collections
#
#  id                :bigint           not null, primary key
#  admin_group       :string
#  division          :string
#  division_page_url :string
#  link_to_policies  :string
#  no_loan_requests  :boolean          default(FALSE), not null
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
    it 'defaults to false' do
      collection = create(:collection)
      expect(collection.no_loan_requests).to be false
    end

    it 'can be enabled on the collection' do
      collection = create(:collection, no_loan_requests: true)
      expect(collection.no_loan_requests).to be true
    end
  end
end

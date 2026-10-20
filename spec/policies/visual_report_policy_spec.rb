require 'rails_helper'

RSpec.describe VisualReportPolicy, type: :policy do
  let(:report_actions) do
    %i[index map_items]
  end

  describe 'anonymous access' do
    let(:policy) { described_class.new({ user: nil, role: nil }, :visual_report) }

    it 'permits visual report actions' do
      report_actions.each do |action|
        expect(policy.public_send("#{action}?" )).to be(true)
      end
    end
  end

  describe 'authenticated access' do
    let(:policy) { described_class.new({ user: build(:user), role: 'user' }, :visual_report) }

    it 'permits visual report actions' do
      report_actions.each do |action|
        expect(policy.public_send("#{action}?" )).to be(true)
      end
    end
  end
end
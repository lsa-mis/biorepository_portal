require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection)}

  context 'with developer role' do
    subject { described_class.new({ user: user, role: "developer" }, collection) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show search create new update edit destroy import items]) }
  end

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, collection) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show search create new update edit destroy import items]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin", collection_ids: [collection.id] }, collection) }

    it { is_expected.to forbid_actions(%i[create new destroy]) }
    it { is_expected.to permit_only_actions(%i[index show search update edit import items]) }
  end

  context 'with user role' do
    subject { described_class.new({ user: user, role: "user" }, collection) }

    it { is_expected.to forbid_actions(%i[create new update edit import]) }
    it { is_expected.to permit_only_actions(%i[index show search items]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, collection) }

    it { is_expected.to forbid_actions(%i[create new update edit import]) }
    it { is_expected.to permit_only_actions(%i[index show search items]) }
  end

end

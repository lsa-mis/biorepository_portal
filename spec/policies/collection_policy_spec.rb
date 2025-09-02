require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection)}

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer" }, collection) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_only_actions(%i[index show search create new update edit destroy import items delete_image]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin" }, collection) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_only_actions(%i[index show search create new update edit destroy import items delete_image]) }
    end

    context 'admin' do
      subject { described_class.new({ user: user, role: "admin", collection_ids: [collection.id] }, collection) }

      it { is_expected.to forbid_actions(%i[create new destroy import]) }
      it { is_expected.to permit_only_actions(%i[index show search update edit items delete_image]) }
    end

    context 'user' do
      subject { described_class.new({ user: user, role: "user" }, collection) }

      it { is_expected.to forbid_actions(%i[create new update edit import delete_image]) }
      it { is_expected.to permit_only_actions(%i[index show search items]) }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none" }, collection) }

      it { is_expected.to forbid_actions(%i[create new update edit import delete_image]) }
      it { is_expected.to permit_only_actions(%i[index show search items]) }
    end
  end

end

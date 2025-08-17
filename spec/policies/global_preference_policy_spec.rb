require 'rails_helper'

RSpec.describe GlobalPreferencePolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:global_preference) { FactoryBot.create(:global_preference)}

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer" }, global_preference) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_only_actions(%i[index show create new delete_preference save_app_prefs app_prefs delete_image]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin" }, global_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference]) }
      it { is_expected.to permit_only_actions(%i[save_app_prefs app_prefs delete_image]) }
    end

    context 'admin role' do
      subject { described_class.new({ user: user, role: "admin" }, global_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference save_app_prefs delete_image]) }
      it { is_expected.to permit_only_actions(%i[app_prefs]) }
    end

    context 'user role' do
      subject { described_class.new({ user: user, role: "user" }, global_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference save_app_prefs app_prefs delete_image]) }
      it { is_expected.to permit_only_actions(%i[]) }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none" }, global_preference) }

      it { is_expected.to forbid_all_actions }
    end
  end

end

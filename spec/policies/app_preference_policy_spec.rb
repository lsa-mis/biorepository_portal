require 'rails_helper'

RSpec.describe AppPreferencePolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:app_preference) { FactoryBot.create(:app_preference)}

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer" }, app_preference) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_only_actions(%i[index show create new delete_preference save_app_prefs app_prefs]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin" }, app_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference]) }
      it { is_expected.to permit_only_actions(%i[save_app_prefs app_prefs]) }
    end

    context 'admin role' do
      subject { described_class.new({ user: user, role: "admin" }, app_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference]) }
      it { is_expected.to permit_only_actions(%i[save_app_prefs app_prefs]) }
    end

    context 'user role' do
      subject { described_class.new({ user: user, role: "user" }, app_preference) }

      it { is_expected.to forbid_actions(%i[index show create new delete_preference save_app_prefs app_prefs]) }
      it { is_expected.to permit_only_actions(%i[]) }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none" }, app_preference) }

      it { is_expected.to forbid_all_actions }
    end
  end

end

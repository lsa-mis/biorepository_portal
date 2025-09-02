require 'rails_helper'

RSpec.describe FaqPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:faq) { FactoryBot.create(:faq) }

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer" }, faq) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy reorder move_up move_down]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin" }, faq) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy reorder move_up move_down]) }
    end

    context 'admin' do
      subject { described_class.new({ user: user, role: "admin" }, faq) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy reorder move_up move_down]) }
    end

    context 'user' do
      subject { described_class.new({ user: user, role: "user" }, faq) }

      it { is_expected.to permit_actions(%i[index show ]) }
      it { is_expected.to forbid_actions(%i[create new update edit destroy reorder move_up move_down]) }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none" }, faq) }

      it { is_expected.to permit_actions(%i[index show ]) }
      it { is_expected.to forbid_actions(%i[create new update edit destroy reorder move_up move_down]) }
    end
  end
end

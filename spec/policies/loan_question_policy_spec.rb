require 'rails_helper'

RSpec.describe LoanQuestionPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:loan_question) { FactoryBot.create(:loan_question) }

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer" }, loan_question) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin" }, loan_question) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy]) }
    end

    context 'admin' do
      subject { described_class.new({ user: user, role: "admin" }, loan_question) }

      it { is_expected.to permit_actions(%i[index show]) }
      it { is_expected.to forbid_actions(%i[create new update edit destroy]) }
    end

    context 'user' do
      subject { described_class.new({ user: user, role: "user" }, loan_question) }

      it { is_expected.to forbid_all_actions }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none" }, loan_question) }

      it { is_expected.to forbid_all_actions }
    end
  end
end

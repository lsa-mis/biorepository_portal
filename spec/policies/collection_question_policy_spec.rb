require 'rails_helper'

RSpec.describe CollectionQuestionPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection)}
  let!(:collection_question) { FactoryBot.create(:collection_question, collection: collection) }

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer", params: { "id" => collection.id.to_s } }, collection_question) }

      it { is_expected.to forbid_actions(%i[index show update edit destroy]) }
      it { is_expected.to permit_actions(%i[new create]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin", params: { "id" => collection.id.to_s } }, collection_question) }

      it { is_expected.to forbid_actions(%i[index show update edit destroy]) }
      it { is_expected.to permit_actions(%i[new create]) }
    end

    context 'admin' do
      subject { described_class.new({ user: user, role: "admin", collection_ids: [collection.id], params: { "id" => collection.id.to_s } }, collection_question) }

      it { is_expected.to forbid_actions(%i[index show update edit destroy]) }
      it { is_expected.to permit_actions(%i[new create]) }
    end

    context 'user' do
      subject { described_class.new({ user: user, role: "user", params: { "id" => collection.id.to_s } }, collection_question) }

      it { is_expected.to forbid_all_actions }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none", params: { "id" => collection.id.to_s } }, collection_question) }

      it { is_expected.to forbid_all_actions }
    end
  end
end

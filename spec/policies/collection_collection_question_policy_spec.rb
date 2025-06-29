require 'rails_helper'

RSpec.describe Collection::CollectionQuestionPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection)}
  let!(:collection_question) { FactoryBot.create(:collection_question, collection: collection) }

  describe 'permissions by role' do
    context 'developer' do
      subject { described_class.new({ user: user, role: "developer", params: { "collection_id" => collection.id.to_s } }, [collection, collection_question]) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy preview move_up move_down]) }
    end

    context 'super_admin' do
      subject { described_class.new({ user: user, role: "super_admin", params: { "collection_id" => collection.id.to_s } }, [collection, collection_question]) }

      it { is_expected.to forbid_actions(%i[]) }
      it { is_expected.to permit_actions(%i[index show create new update edit destroy preview move_up move_down]) }
    end

    context 'admin' do
      subject { described_class.new({ user: user, role: "admin", collection_ids: [collection.id], params: { "collection_id" => collection.id.to_s } }, [collection, collection_question]) }

      it { is_expected.to permit_actions(%i[index show create new update edit destroy preview move_up move_down]) }
      it { is_expected.to forbid_actions(%i[]) }
    end

    context 'user' do
      subject { described_class.new({ user: user, role: "user", params: { "collection_id" => collection.id.to_s } }, [collection, collection_question]) }

      it { is_expected.to forbid_all_actions }
    end

    context 'none' do
      subject { described_class.new({ user: user, role: "none", params: { "collection_id" => collection.id.to_s } }, [collection, collection_question]) }

      it { is_expected.to forbid_all_actions }
    end
  end
end

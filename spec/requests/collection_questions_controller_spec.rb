require 'rails_helper'

RSpec.describe CollectionQuestion, type: :request do
  let!(:collection) { FactoryBot.create(:collection) }

  describe 'GET /collections/:collection_id/collection_questions' do
    context 'as super_admin' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection:) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'renders index with 200' do
        get collection_collection_questions_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it 'shows New and Preview buttons' do
        get collection_collection_questions_path(collection)
        expect(response.body).to include('New Collection Question')
        expect(response.body).to include('Preview Collection Questions')
      end

      it "should display the Up and Down and Delete buttons" do
        get collection_collection_questions_path(collection)
        expect(response.body).to include("Up")
        expect(response.body).to include("Down")
        expect(response.body).to include('bi-trash-fill')
      end
    end

    context 'as collection admin' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        
        mock_login(admin_user)
      end

      it 'renders index with 200' do
        get collection_collection_questions_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it 'shows New and Preview buttons' do
        get collection_collection_questions_path(collection)
        expect(response.body).to include('New Collection Question')
        expect(response.body).to include('Preview Collection Questions')
      end

      it "shows Up/Down/Delete buttons" do
        get collection_collection_questions_path(collection)
        expect(response.body).to include("Up")
        expect(response.body).to include("Down")
        expect(response.body).to include('bi-trash-fill')
      end
    end

    context 'as regular user' do
      let!(:user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(user)
      end

      it 'denies access to new collection question form' do
        get new_collection_collection_question_path(collection)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /collections/:collection_id/collection_questions/:id/edit' do
    context 'as super_admin' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(super_admin_user.email)

        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)

        mock_login(super_admin_user)
      end

      it 'returns 200' do
        get edit_collection_collection_question_path(collection, question)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as collection admin' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(admin_user.email)

        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)

        mock_login(admin_user)
      end

      it 'returns 200' do
        get edit_collection_collection_question_path(collection, question)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as regular user' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(user.email)

        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)

        mock_login(user)
      end

      it 'shows not authorized alert' do
        get edit_collection_collection_question_path(collection, question)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /collections/:collection_id/collection_questions/:id' do
    context 'as super_admin' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)

        mock_login(super_admin_user)
      end

      it 'destroys the collection question and responds to turbo_stream' do
        expect {
          delete collection_collection_question_path(collection, question), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change(CollectionQuestion, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'as collection admin' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:question) { FactoryBot.create(:collection_question, collection: collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)

        mock_login(admin_user)
      end

      it 'destroys the collection question and responds to turbo_stream' do
        expect {
          delete collection_collection_question_path(collection, question), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change(CollectionQuestion, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'GET /collections/:collection_id/collection_questions/preview' do
    let!(:question1) { FactoryBot.create(:collection_question, collection:, question: "Q1", position: 1) }
    let!(:question2) { FactoryBot.create(:collection_question, collection:, question: "Q2", position: 2) }

    context 'as super_admin' do
      let!(:super_admin_user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'returns 200 and displays questions' do
        get preview_collection_collection_questions_path(collection)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Q1")
        expect(response.body).to include("Q2")
      end
    end

    context 'as collection admin' do
      let!(:admin_user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'returns 200 and displays questions' do
        get preview_collection_collection_questions_path(collection)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Q1")
        expect(response.body).to include("Q2")
      end
    end

    context 'as regular user' do
      let!(:user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(user)
      end

      it 'redirects and shows unauthorized flash' do
        get preview_collection_collection_questions_path(collection)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

  describe 'PATCH #move_up / #move_down' do
    let!(:question1) { FactoryBot.create(:collection_question, collection:, question: "First", position: 1) }
    let!(:question2) { FactoryBot.create(:collection_question, collection:, question: "Second", position: 2) }

    shared_examples 'reorders questions' do
      it 'moves the second question up' do
        patch move_up_collection_collection_question_path(collection, question2)
        expect(response).to redirect_to(collection_collection_questions_path)
        expect(flash[:notice]).to eq("Question moved up.")
        expect(collection.collection_questions.order(:position).first).to eq(question2.reload)
      end

      it 'moves the first question down' do
        patch move_down_collection_collection_question_path(collection, question1)
        expect(response).to redirect_to(collection_collection_questions_path)
        expect(flash[:notice]).to eq("Question moved down.")
        expect(collection.collection_questions.order(:position).last).to eq(question1.reload)
      end
    end

    context 'as super_admin' do
      let!(:super_admin_user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end

      include_examples 'reorders questions'
    end

    context 'as collection admin' do
      let!(:admin_user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      include_examples 'reorders questions'
    end

    context 'as regular user' do
      let!(:user) { FactoryBot.create(:user) }

      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(user)
      end

      it 'cannot move up' do
        patch move_up_collection_collection_question_path(collection, question2)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it 'cannot move down' do
        patch move_down_collection_collection_question_path(collection, question1)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

end

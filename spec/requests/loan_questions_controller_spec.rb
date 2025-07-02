require 'rails_helper'

RSpec.describe LoanQuestion, type: :request do

  context 'index action' do

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }
      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        mock_login(super_admin_user)
      end

      it 'returns 200' do
        get loan_questions_path
        expect(response).to have_http_status(200)
      end

      it 'should display Loan Questions link on the index page' do
        get root_path
        expect(response.body).to include("Loan Questions")
      end

      it "should display the New Loan Question and Preview Loan Questions buttons" do
        get loan_questions_path
        expect(response.body).to include("New Loan Question")
        expect(response.body).to include("Preview Loan Questions")
      end

      it "should display the Up and Down and Delete buttons" do
        get loan_questions_path
        expect(response.body).to include("Up")
        expect(response.body).to include("Down")
        expect(response.body).to include('bi-trash-fill')
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'should display Loan Questions link on the index page' do
        get root_path
        expect(response).to have_http_status(200)
        expect(response.body).to include("Loan Questions")
      end

      it "should not display the New Loan Question button" do
        get loan_questions_path
        expect(response.body).not_to include("New Loan Question")
      end

      it "should display the Preview Loan Questions buttons" do
        get loan_questions_path
        expect(response.body).to include("Preview Loan Questions")
      end

      it "should not display the Up and Down and Delete buttons" do
        get loan_questions_path
        expect(response.body).not_to include("Up")
        expect(response.body).not_to include("Down")
        expect(response.body).not_to include('bi-trash-fill')
      end

    end

    context 'with user role' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }

      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        mock_login(user)
      end

      it 'should not display Loan Questions link on the index page' do
        get root_path
        expect(response.body).not_to include("Loan Questions")
      end

      it 'should display alert "You are not authorized to perform this action"' do
        get new_loan_question_path
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

    end
  end

  context 'edit action' do

    context 'with super admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        mock_login(super_admin_user)
      end

      it 'returns 200' do
        get edit_loan_question_path(loan_question)
        expect(response).to have_http_status(200)
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'should display alert "You are not authorized to perform this action"' do
        get edit_loan_question_path(loan_question)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context 'with user role' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(user)
      end

      it 'should display alert "You are not authorized to perform this action"' do
        get edit_loan_question_path(loan_question)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

  end

  context 'destroy action' do
    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        mock_login(super_admin_user)
      end

      it 'destroys the loan question and redirects' do
        expect {
          delete loan_question_path(loan_question)
        }.to change(LoanQuestion, :count).by(-1)
        expect(response.body).to include('Loan question was successfully deleted')
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:loan_question) { FactoryBot.create(:loan_question) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'does not destroy the loan question and shows not authorized alert' do
        expect {
          delete loan_question_path(loan_question)
        }.not_to change(LoanQuestion, :count)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end
end

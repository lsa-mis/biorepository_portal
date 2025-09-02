require 'rails_helper'

RSpec.describe LoanRequestsController, type: :request do
  let!(:user) { FactoryBot.create(:user, first_name: 'John', last_name: 'Doe', affiliation: 'Test University') }
  let!(:collection) { FactoryBot.create(:collection) }

  let!(:incomplete_user) { FactoryBot.create(:user, first_name: nil, last_name: 'Doe', affiliation: 'Test University') }
  let!(:loan_question) { FactoryBot.create(:loan_question, required: true) }
  let!(:collection_question) { FactoryBot.create(:collection_question, collection: collection, required: true) }
  let!(:checkout) { FactoryBot.create(:checkout, user: user) }
  let!(:requestable) { FactoryBot.create(:requestable, checkout: checkout, preparation: FactoryBot.create(:preparation, item: FactoryBot.create(:item, collection: collection))) }

  describe 'POST #enable' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      mock_login(admin_user)
    end

    it 'redirects to new loan request with preview parameter' do
      post enable_loan_request_path
      expect(response).to redirect_to(new_loan_request_path(preview: true))
    end
  end

  describe 'GET #show with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }
    let!(:loan_request) { FactoryBot.create(:loan_request, user: user) }

    before do
      uniqname = get_uniqname(admin_user.email)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
      mock_login(admin_user)
    end

    it 'displays the loan request successfully' do
      get loan_request_path(loan_request)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Loan Request Details")
      expect(response.body).to include(user.display_name)
    end
  end

  describe 'GET #show with none role' do
    let!(:loan_request) { FactoryBot.create(:loan_request, user: user) }

    before do
      uniqname = get_uniqname(user.email)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
      mock_login(user)
    end

    it 'displays the not authorized message' do
      get loan_request_path(loan_request)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to redirect_to(collections_path)
    end
  end

  describe 'GET #new' do
    before do
      mock_login(user)
    end

    it 'displays the user info fields' do
      get new_loan_request_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("First Name")
      expect(response.body).to include("User Information")
    end
  end

  describe 'GET #new when user has incomplete information' do
    before do
      mock_login(incomplete_user)
      
    end
    it 'displays step two successfully' do
      get new_loan_request_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("User Information")
      
      # Try to proceed to step_two with incomplete user info
      get step_two_path
      expect(response).to redirect_to(new_loan_request_path)
      expect(flash[:alert]).to eq("User information is incomplete.")
    end
  end

  describe 'GET #step_two with no answer to loan question' do
    before do
      mock_login(user)
    end

    context 'displays step two' do
      it 'displays the loan questions and alert to answer questions' do
        get step_two_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Loan Questionnaire Answers")

        get step_three_path
        expect(response).to redirect_to(step_two_path)
        expect(flash[:alert]).to eq("Please answer all loan questions.")
      end
    end
  end

  describe 'GET #step_two with an answer to loan question' do
    let!(:loan_answer) { FactoryBot.create(:loan_answer, user: user, loan_question: loan_question, answer: "my answer") }
    before do
      mock_login(user)
    end

    it 'displays the loan questions and goes to step three' do
      get step_two_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Loan Questionnaire Answers")

      get step_three_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Collection Questionnaire Answers")
    end
  end

  describe 'GET #step_three' do
    let!(:loan_answer) { FactoryBot.create(:loan_answer, user: user, loan_question: loan_question, answer: "my answer") }

    before do
      mock_login(user)
    end

    context 'when collection questions are not answered' do
      it 'displays step three successfully but shows an alert' do
        get step_three_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Collection Questionnaire Answers")
        get step_four_path
        expect(response).to redirect_to(step_three_path)
        expect(flash[:alert]).to eq("Please answer all collection questions.")
      end
    end

    context 'when loan questions are answered' do
      let!(:collection_answer) { FactoryBot.create(:collection_answer, user: user, collection_question: collection_question, answer: 'Test answer') }

      it 'redirects to step_two with alert' do
        get step_three_path
        get step_four_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Shipping Information")
      end
    end
  end

  describe 'GET #step_four' do
    let!(:collection_answer) { FactoryBot.create(:collection_answer, user: user, collection_question: collection_question, answer: 'Test answer') }

    before do
      mock_login(user)
    end

    context 'with no shipping addresses' do
      it 'displays step four successfully but shows an alert' do
        get step_four_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Shipping Information")
        get step_five_path
        expect(response).to redirect_to(step_four_path)
        expect(flash[:alert]).to eq("Add a Shipping address.")
      end
    end

    context 'with shipping addresses but none selected' do
      let!(:address) { FactoryBot.create(:address, user: user) }

      it 'goes to step_five' do
        get step_four_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Shipping Information")

        get step_five_path
        expect(response).to redirect_to(step_four_path)
        expect(flash[:alert]).to eq("Select an address to ship to.")
      end
    end

    context 'with selected shipping address' do
      let!(:address) { FactoryBot.create(:address, user: user, primary: true) }

      it 'goes to step_five' do
        get step_four_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Shipping Information")
        expect(response.body).to include("value=\"#{address.id}\"")
        expect(response.body).to include("checked=\"checked\"")

        get step_five_path, params: { shipping_address_id: address.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Items for Checkout")
      end
    end

  end

  describe 'POST #send_loan_request' do
    let!(:address) { FactoryBot.create(:address, user: user) }

    before do
      mock_login(user)
      allow(PdfGenerator).to receive(:new).and_return(double(generate_pdf_content: 'pdf content'))
      allow(RequestMailer).to receive_message_chain(:send_loan_request, :deliver_now)
      allow(RequestMailer).to receive_message_chain(:confirmation_loan_request, :deliver_now)
    end

    context 'with valid parameters' do
      let(:valid_params) { { shipping_address_id: address.id } }

      it 'creates a loan request successfully' do
        expect {
          post send_loan_request_path, params: valid_params
        }.to change(LoanRequest, :count).by(1)

        expect(response).to redirect_to(checkout_path)
        expect(flash[:notice]).to eq('Loan request sent with CSV and PDF attached.')
      end

      it 'assigns correct attributes to loan request' do
        post send_loan_request_path, params: valid_params
        
        loan_request = LoanRequest.last
        expect(loan_request.user).to eq(user)
        expect(loan_request.send_to).to be_present
      end

      it 'sends emails' do
        expect(RequestMailer).to receive(:send_loan_request).and_return(double(deliver_now: true))
        expect(RequestMailer).to receive(:confirmation_loan_request).and_return(double(deliver_now: true))
        
        post send_loan_request_path, params: valid_params
      end
    end

    context 'when checkout is empty' do
      before do
        checkout.requestables.destroy_all
      end

      it 'redirects to root with alert' do
        post send_loan_request_path, params: { shipping_address_id: address.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('No items in checkout.')
      end
    end

    context 'when loan request fails to save' do
      before do
        allow_any_instance_of(LoanRequest).to receive(:save).and_return(false)
        allow_any_instance_of(LoanRequest).to receive(:errors).and_return(
          double(full_messages: ['Sample error'])
        )
      end

      it 'redirects to new loan request with error message' do
        post send_loan_request_path, params: { shipping_address_id: address.id }
        expect(response).to redirect_to(new_loan_request_path)
        expect(flash[:alert]).to include('Failed to create loan request')
      end
    end
  end

  describe 'validation behavior' do
    before do
      mock_login(user)
    end

    describe 'required question validation' do
      let!(:loan_answer) { FactoryBot.create(:loan_answer, user: user, loan_question: loan_question, answer: "my answer") }
      let!(:required_question) { FactoryBot.create(:loan_question, required: true) }
      let!(:optional_question) { FactoryBot.create(:loan_question, required: false) }

      it 'prevents progression when required questions are not answered' do

        get step_three_path
        expect(response).to redirect_to(step_two_path)
        expect(flash[:alert]).to eq('Please answer all loan questions.')
      end

      it 'allows progression when required questions are answered but optional ones are not' do
        FactoryBot.create(:loan_answer, user: user, loan_question: required_question, answer: 'Valid answer')
        
        get step_three_path
        expect(response).to have_http_status(:success)
      end

      it 'prevents progression when required questions have blank answers' do
        FactoryBot.create(:loan_answer, user: user, loan_question: required_question, answer: '')
        
        get step_three_path
        expect(response).to redirect_to(step_two_path)
        expect(flash[:alert]).to eq('Please answer all loan questions.')
      end
    end

    describe 'shipping address validation' do
      context 'when valid shipping address is provided' do
        let!(:address) { FactoryBot.create(:address, user: user) }
        it 'allows access to step five' do
          get step_five_path, params: { shipping_address_id: address.id }
          expect(response).to have_http_status(:success)
        end
      end

      context 'when no shipping address is provided' do
        it 'redirects with error message' do
          get step_five_path
          expect(response).to redirect_to(step_four_path)
          expect(flash[:alert]).to eq('Add a Shipping address.')
        end
      end

    end
  end

  describe 'authentication and authorization' do
    context 'when user is not logged in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'handles unauthenticated access appropriately' do
        get new_loan_request_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
      end
    end
  end

end
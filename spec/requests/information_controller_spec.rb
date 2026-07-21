require 'rails_helper'

RSpec.describe InformationRequestsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:collection) { FactoryBot.create(:collection) }
  let(:checkout_items) { ["Specimen A123", "Specimen B456", "Specimen C789"] }
  let(:collection_ids) { [1, 2] }

  before do
    uniqname = get_uniqname(user.email)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
    mock_login(user)
    # get_checkout_items is called both in `new` and inside send_information_request's
    # server-side filter. Stub it so submitted items can actually pass the filter.
    allow_any_instance_of(InformationRequestsController)
      .to receive(:get_checkout_items)
      .and_return([checkout_items, collection_ids])
  end

  describe 'GET /new_information_request' do
    it 'renders the information request form' do
      get new_information_request_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create Information Request")
      expect(response.body).to include("Email Message")
      expect(response.body).to include("Submit")
    end

    it 'lists loanable and information request only checkout items' do
      allow_any_instance_of(InformationRequestsController)
        .to receive(:get_checkout_items)
        .and_call_original

      loan_collection = FactoryBot.create(
        :collection,
        division: 'Loan Collection',
        admin_group: 'loan-collection-admins',
        no_loan_requests: false
      )
      information_only_collection = FactoryBot.create(
        :collection,
        division: 'Info Only Collection',
        admin_group: 'info-only-collection-admins',
        no_loan_requests: true
      )
      loan_item = FactoryBot.create(:item, collection: loan_collection, catalog_number: 'LOAN-123')
      information_only_item = FactoryBot.create(:item, collection: information_only_collection, catalog_number: 'INFO-456')
      FactoryBot.create(:identification, item: loan_item, scientific_name: 'Loanable species')
      FactoryBot.create(:identification, item: information_only_item, scientific_name: 'Information species')
      loan_preparation = FactoryBot.create(:preparation, item: loan_item, prep_type: 'Tissue')
      information_only_preparation = FactoryBot.create(:preparation, item: information_only_item, prep_type: 'Skin')
      checkout = user.checkout || FactoryBot.create(:checkout, user: user)
      FactoryBot.create(:requestable, checkout: checkout, preparation: loan_preparation, item_id: loan_item.id)
      FactoryBot.create(:requestable, checkout: checkout, preparation: information_only_preparation, item_id: information_only_item.id)

      get new_information_request_path

      expect(response.body).to include('Loan Collection, Catalog Number: LOAN-123')
      expect(response.body).to include('Info Only Collection, Catalog Number: INFO-456')
    end
  end

  describe 'POST /send_information_request' do
    context 'with valid parameters' do
      it 'creates a new Information Request and redirects' do
        post send_information_request_path, params: {
          information_request: {
            question: "Can I get details on specimen 123?",
            send_to: "curator@example.com"
          }
        }
        expect(response).to redirect_to(faqs_path)
        get profile_path
        expect(response.body).to include("curator@example.com")
      end
    end

    context 'with invalid parameters' do
      it 're-renders the form with errors' do
        post send_information_request_path, params: {
          information_request: {
            question: "",
            send_to: ""
          }
        }
        expect(response.body).to include("Failed to send information request.")
      end
    end

    context 'with selected checkout items' do
      it 'saves only the items that are actually in the checkout' do
        post send_information_request_path, params: {
          information_request: {
            question: "Can I get details on specimen 123?",
            send_to: "curator@example.com"
          },
          selected_checkout_items: ["Specimen A123", "Specimen B456"]
        }

        expect(response).to redirect_to(faqs_path)
        expect(InformationRequest.last.checkout_items).to match_array(["Specimen A123", "Specimen B456"])
      end

      it 'filters out items that are not actually in the checkout' do
        post send_information_request_path, params: {
          information_request: {
            question: "Can I get details on specimen 123?",
            send_to: "curator@example.com"
          },
          selected_checkout_items: ["Specimen A123", "Fake Item Not In Checkout"]
        }

        expect(InformationRequest.last.checkout_items).to eq(["Specimen A123"])
        expect(InformationRequest.last.checkout_items).not_to include("Fake Item Not In Checkout")
      end
    end

    context 'without any selected checkout items' do
      it 'saves an empty checkout_items array' do
        post send_information_request_path, params: {
          information_request: {
            question: "Can I get details on specimen 123?",
            send_to: "curator@example.com"
          }
        }

        expect(response).to redirect_to(faqs_path)
        expect(InformationRequest.last.checkout_items).to eq([])
      end
    end
  end

  describe 'GET /profile' do
    it 'shows submitted information requests' do
      post send_information_request_path, params: {
        information_request: {
          question: "Can I get details on specimen 123?",
          send_to: "example@example.com"
        }
      }
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Submitted Information Requests")
      expect(response.body).to include("example@example.com")
    end
  end

  describe 'GET /information_request_show_modal_path/:id' do
    let(:information_request) { FactoryBot.create(:information_request, user: user, question: "Can I get details on specimen 123?", send_to: "example@example.com") }
    
    it 'renders a turbo stream modal for the request' do
      get information_request_show_modal_path(information_request), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Submitted Information Request")
      expect(response.body).to include("Can I get details on specimen 123?")
      expect(response.body).to include("example@example.com")
      expect(response.body).to include("No checkout items included")
    end
  end
end

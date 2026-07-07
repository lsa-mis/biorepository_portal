require 'rails_helper'

RSpec.describe InformationRequestsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:checkout_items) { ["Specimen A123", "Specimen B456", "Specimen C789"] }
  let(:collection_ids) { [1, 2] }

  before do
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

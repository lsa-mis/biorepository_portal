require 'rails_helper'

RSpec.describe InformationRequestsController, type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    mock_login(user)
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
        expect(response).to redirect_to(root_path)
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

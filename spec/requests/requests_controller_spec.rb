require 'rails_helper'

RSpec.describe RequestsController, type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    mock_login(user)
  end

  describe 'GET /information_request' do
    it 'renders the information request form' do
      get information_request_path
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

  describe 'GET /show_information_request/:id' do
    let(:information_request) { FactoryBot.create(:information_request, user: user, question: "Can I get details on specimen 123?", send_to: "example@example.com") }
    it 'renders a turbo stream modal for the request' do

      get show_information_request_path(information_request), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Submitted Information Request")
      expect(response.body).to include("Can I get details on specimen 123?")
      expect(response.body).to include("example@example.com")
      expect(response.body).to include("No checkout items included")
    end
  end

  describe 'GET /loan_request' do
    it 'renders the loan request form' do
      get loan_request_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Loan Request").or include("Please answer all required questions")
    end
  end

  describe 'POST /send_loan_request' do
    let(:checkout) { instance_double("Checkout", requestables: []) }

    context 'when checkout is missing or empty' do
      it 'redirects with an alert' do
        expect(post send_loan_request_path, params: { checkout: nil }).to redirect_to(root_path)
        expect(flash[:alert]).to eq("No items in checkout.")
      end
    end

    context 'with valid data and completed fields' do
      before do
        # Set up mock checkout items
        collection = FactoryBot.create(:collection)
        item = FactoryBot.create(:item, collection: collection)
        prep = FactoryBot.create(:preparation, item: item, count: 1)

        requestable = double("Requestable", preparation: prep, count: 1, saved_for_later: false)
        checkout = double("Checkout", requestables: [requestable])

        allow_any_instance_of(RequestsController).to receive(:get_checkout_items).and_return("Test Item Data")
        allow_any_instance_of(RequestsController).to receive(:build_collection_answers).and_return({})
        allow_any_instance_of(RequestsController).to receive(:check_missing_answers).and_return(false)
        allow_any_instance_of(RequestsController).to receive(:create_csv_file).and_return(Tempfile.new)
        allow_any_instance_of(RequestsController).to receive(:attach_attachments_from_answers)

        # Attach PDF/CSV stubs
        allow(Tempfile).to receive(:new).and_return(Tempfile.new("loan_request"))
        allow(PdfGenerator).to receive_message_chain(:new, :generate_pdf_content).and_return("PDF content")
      end

      it 'processes and sends the loan request' do
        expect {
          post send_loan_request_path
        }.to_not raise_error
      end
    end
  end
end

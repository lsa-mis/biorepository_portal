require 'rails_helper'

RSpec.describe LoanRequestsController, type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    mock_login(user)
  end

  describe 'GET /new_loan_request' do
    it 'renders the loan request form' do
      get new_loan_request_path
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

        allow_any_instance_of(LoanRequestsController).to receive(:get_checkout_items).and_return("Test Item Data")
        allow_any_instance_of(LoanRequestsController).to receive(:build_collection_answers).and_return({})
        allow_any_instance_of(LoanRequestsController).to receive(:check_missing_answers).and_return(false)
        allow_any_instance_of(LoanRequestsController).to receive(:create_csv_file).and_return(Tempfile.new)
        allow_any_instance_of(LoanRequestsController).to receive(:attach_attachments_from_answers)

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

  describe 'GET /show_loan_request/:id' do
    let(:loan_request) { FactoryBot.create(:loan_request, user: user) }
    
    it 'shows the loan request details' do
      get loan_request_path(loan_request)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Loan Request Details")
    end
  end
end

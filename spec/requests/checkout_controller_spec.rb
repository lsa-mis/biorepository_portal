require 'rails_helper'

RSpec.describe CheckoutController, type: :request do
  let!(:collection) { FactoryBot.create(:collection) }
  let!(:item) { FactoryBot.create(:item, collection: collection) }
  let!(:preparation) { FactoryBot.create(:preparation, item: item) }

  context 'Checkout Functionality' do

    it 'returns 200' do
      get checkout_path
      expect(response).to have_http_status(200)
    end

    it 'should display Checkout and Save for Later on the index page, but not Send Loan Request' do
      get checkout_path
      expect(response.body).to include("Checkout")
      expect(response.body).to include("Saved for Later")
      expect(response.body).not_to include("Send Loan Request")
    end

    it 'should add to checkout' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include(preparation.item.name)
    end

    it 'should not display Send Loan Request Button when there are no preparations in the cart' do
      get checkout_path
      expect(response).to have_http_status(200)
      expect(response.body).not_to include("Send Loan Request")
    end

    it 'should display Send Loan Request Button when there are preparations in the cart' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("Send Loan Request")
    end

    it 'should be saved for later' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("MPABI")
      post checkout_save_for_later_path, params: { id: preparation.id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("Move to Checkout")
    end

    it 'should remove from checkout from Saved for Later' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("MPABI")
      post checkout_save_for_later_path, params: { id: preparation.id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("Move to Checkout")
      post checkout_remove_path, params: { id: Requestable.find_by(preparation_id: preparation.id).id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).not_to include("MPABI")
    end

    it 'should move back to checkout from Saved for Later' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("MPABI")
      post checkout_save_for_later_path, params: { id: preparation.id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("Move to Checkout")
      post checkout_move_back_path, params: { id: preparation.id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("You don't have any preparations saved for later.")
      expect(response.body).to include("MPABI")
    end

    it 'should remove from checkout' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("MPABI")
      post checkout_remove_path, params: { id: Requestable.find_by(preparation_id: preparation.id).id }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).not_to include("MPABI")
    end

    it 'should allow adding to count' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("MPABI")
      post checkout_change_path, params: { id: preparation.id, count: 3 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response.body).to include("<option selected=\"selected\" value=\"3\">3</option>")
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include("<option selected=\"selected\" value=\"3\">3</option>")
    end
  end

end

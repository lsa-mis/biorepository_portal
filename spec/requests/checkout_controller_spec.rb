require 'rails_helper'

RSpec.describe CheckoutController, type: :request do
  let!(:super_admin_user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection) }
  let!(:item) { FactoryBot.create(:item, collection: collection) }
  let!(:preparation) { FactoryBot.create(:preparation, item: item) }


  context 'Checkout Functionality' do
    # before do
    #   uniqname = get_uniqname(super_admin_user.email)
    #   allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
    #   allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
    #   mock_login(super_admin_user)
    # end

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
      expect(response.body).to include("MPABI")
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

    end
  end

    # Additional contexts for admin and other roles can be added here.
end
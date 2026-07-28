require 'rails_helper'

RSpec.describe CheckoutController, type: :request do
  let!(:collection) { FactoryBot.create(:collection) }
  let!(:item) { FactoryBot.create(:item, collection: collection) }
  let!(:preparation) { FactoryBot.create(:preparation, item: item) }
  let!(:identification) { FactoryBot.create(:identification, item: item) }

  context 'Checkout Functionality' do

    it 'returns 200' do
      get checkout_path
      expect(response).to have_http_status(200)
    end

    it 'should display Checkout and Save for Later on the index page, but not Send Loan Request' do
      get checkout_path
      expect(response.body).to include("Checkout")
      expect(response.body).to include("Saved for Later")
      expect(response.body).not_to include("Sign In to Send Loan Request")
    end

    it 'should add to checkout' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)
      get checkout_path
      expect(response.body).to include(preparation.item.display_name)
    end

    it 'should add information request only items to checkout' do
      information_only_collection = FactoryBot.create(
        :collection,
        division: 'Info Only',
        admin_group: 'info-only-admins',
        no_loan_requests: true
      )
      information_only_item = FactoryBot.create(:item, collection: information_only_collection)
      information_only_preparation = FactoryBot.create(:preparation, item: information_only_item)

      post checkout_add_path, params: { id: information_only_preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)

      get checkout_path
      expect(response.body).to include(information_only_preparation.item.display_name)
      expect(response.body).to include('(1)')
      expect(response.body).to include('Information Request')
      expect(response.body).not_to include('Sign In to Send Loan Request')
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

    it 'does not count checkout items whose preparation is no longer available' do
      post checkout_add_path, params: { id: preparation.id, count: 1 }, headers: {'Accept' => 'text/vnd.turbo-stream.html'}
      expect(response).to have_http_status(200)

      get checkout_path
      expect(response.body).to include("(1)")

      preparation.update!(count: 0)

      get checkout_path
      expect(response.body).not_to include("(1)")
    end
  end

  describe 'GET #show with none role' do
    let!(:user) { FactoryBot.create(:user, first_name: 'John', last_name: 'Doe', affiliation: 'Test University') }

    before do
      uniqname = get_uniqname(user.email)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
      mock_login(user)
    end

    it 'should not display Send Loan Request Button when there are no preparations in the cart' do
      get checkout_path
      expect(response).to have_http_status(200)
      expect(response.body).not_to include("Send Loan Request")
    end

  end

end

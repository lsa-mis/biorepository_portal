require 'rails_helper'

RSpec.describe AppPreferencesController, type: :request do
  let(:developer) { FactoryBot.create(:user) }
  let!(:mpabi_collection) { FactoryBot.create(:collection, division: "MPABI", admin_group: "mpabi-admins") }
  let!(:zoo_collection) { FactoryBot.create(:collection, division: "ZOO", admin_group: "zoo-admins") }

  before do
    uniqname = get_uniqname(developer.email)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(true)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "mpabi-admins").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "zoo-admins").and_return(false)
    mock_login(developer)
  end

  describe 'GET /app_preferences/app_prefs' do
    before do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "show_barcode")
      FactoryBot.create(:app_preference, collection: zoo_collection, name: "show_barcode")
    end

    it 'renders collection preferences without querying preferences once per collection' do
      collection_preference_loads = []
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _unique_id, payload|
        collection_preference_loads << payload[:sql] if payload[:sql].match?(/SELECT "app_preferences"\.\* FROM "app_preferences" WHERE "app_preferences"\."collection_id" =/)
      end

      get app_prefs_path

      expect(response).to have_http_status(:success)
      expect(collection_preference_loads).to be_empty
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end

    it 'renders placeholders on string preferences' do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "catalog_prefix", pref_type: :string, placeholder: "Enter catalog prefix")

      get app_prefs_path

      expect(response.body).to include('placeholder="Enter catalog prefix"')
    end

    it 'renders no_loan_requests as a radio group instead of a switch' do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean)

      get app_prefs_path

      document = Nokogiri::HTML(response.body)
      fieldset = document.at_css('fieldset')

      expect(response.body).not_to include('name="app_prefs[' + mpabi_collection.id.to_s + '][no_loan_requests]"')
      expect(fieldset.at_css('legend').text).to eq("Loan Requests")
      expect(fieldset.css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"]').map { |input| input["value"] }).to contain_exactly("allowed", "information_requests_only")
      expect(fieldset.text).to include("Collection allows Loan Requests")
      expect(fieldset.text).to include("Collection doesn’t allow Loan Requests")
      expect(fieldset.text).to include("Information Requests only")
    end

    it 'selects the allows option when loan requests are allowed' do
      mpabi_collection.update!(no_loan_requests: false)
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean)

      get app_prefs_path

      document = Nokogiri::HTML(response.body)
      allowed = document.at_css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"][value="allowed"]')
      information_requests_only = document.at_css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"][value="information_requests_only"]')

      expect(allowed["checked"]).to eq("checked")
      expect(information_requests_only["checked"]).to be_nil
    end

    it 'selects the information requests only option when loan requests are disabled' do
      mpabi_collection.update!(no_loan_requests: true)
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean)

      get app_prefs_path

      document = Nokogiri::HTML(response.body)
      allowed = document.at_css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"][value="allowed"]')
      information_requests_only = document.at_css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"][value="information_requests_only"]')

      expect(allowed["checked"]).to be_nil
      expect(information_requests_only["checked"]).to eq("checked")
    end

    it 'selects the allows option by default when no preference value is set' do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean, value: nil)

      get app_prefs_path

      document = Nokogiri::HTML(response.body)
      allowed = document.at_css('input[type="radio"][name="app_prefs[' + mpabi_collection.id.to_s + '][loan_requests_policy]"][value="allowed"]')

      expect(allowed["checked"]).to eq("checked")
    end
  end

  describe 'POST /app_preferences' do
    it 'creates one app preference per collection without reloading each collection' do
      collection_loads = []
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _unique_id, payload|
        collection_loads << payload[:sql] if payload[:sql].match?(/SELECT "collections"\.\* FROM "collections" WHERE "collections"\."id" =/)
      end

      post app_preferences_path, params: {
        app_preference: {
          name: "show_barcode",
          description: "Show barcode",
          pref_type: "boolean"
        }
      }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(AppPreference.where(name: "show_barcode").count).to eq(2)
      expect(collection_loads).to be_empty
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end

    it 'creates string preferences with placeholder text' do
      post app_preferences_path, params: {
        app_preference: {
          name: "collection_email_to_send_requests",
          description: "Collection request email",
          pref_type: "string",
          placeholder: "curator@example.edu"
        }
      }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(AppPreference.where(name: "collection_email_to_send_requests").pluck(:placeholder).uniq).to eq(["curator@example.edu"])
    end
  end

  describe 'POST /app_preferences/app_prefs' do
    before do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean, value: "0")
      FactoryBot.create(:app_preference, collection: zoo_collection, name: "no_loan_requests", pref_type: :boolean, value: "0")
    end

    it 'stores no_loan_requests as false when loan requests are allowed' do
      mpabi_collection.update!(no_loan_requests: true)

      post app_prefs_path, params: {
        app_prefs: {
          mpabi_collection.id => {
            loan_requests_policy: "allowed"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(mpabi_collection.reload.no_loan_requests).to be false
      expect(zoo_collection.reload.no_loan_requests).to be false
    end

    it 'stores no_loan_requests as true when only information requests are allowed' do
      post app_prefs_path, params: {
        app_prefs: {
          zoo_collection.id => {
            loan_requests_policy: "information_requests_only"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(zoo_collection.reload.no_loan_requests).to be true
    end

    it 'stores elevated user changes for collections outside their admin collection ids' do
      uniqname = get_uniqname(developer.email)
      allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "mpabi-admins").and_return(true)
      mock_login(developer)

      post app_prefs_path, params: {
        app_prefs: {
          zoo_collection.id => {
            loan_requests_policy: "information_requests_only"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(zoo_collection.reload.no_loan_requests).to be true
    end

    it 'preserves an existing no_loan_requests value when the policy parameter is absent' do
      mpabi_collection.update!(no_loan_requests: true)
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "show_barcode", pref_type: :boolean, value: "0")

      post app_prefs_path, params: {
        app_prefs: {
          mpabi_collection.id => {
            show_barcode: "1"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(mpabi_collection.reload.no_loan_requests).to be true
    end

    it 'does not interpret unexpected policy values as true' do
      mpabi_collection.update!(no_loan_requests: false)

      post app_prefs_path, params: {
        app_prefs: {
          mpabi_collection.id => {
            loan_requests_policy: "yes_please"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(mpabi_collection.reload.no_loan_requests).to be false
    end
  end
end

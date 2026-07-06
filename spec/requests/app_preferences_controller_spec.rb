require 'rails_helper'

RSpec.describe AppPreferencesController, type: :request do
  let(:developer) { FactoryBot.create(:user) }
  let!(:mpabi_collection) { FactoryBot.create(:collection, division: "MPABI", admin_group: "mpabi-admins") }
  let!(:zoo_collection) { FactoryBot.create(:collection, division: "ZOO", admin_group: "zoo-admins") }

  before do
    uniqname = get_uniqname(developer.email)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(true)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
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
  end

  describe 'POST /app_preferences/app_prefs' do
    before do
      FactoryBot.create(:app_preference, collection: mpabi_collection, name: "no_loan_requests", pref_type: :boolean, value: "0")
      FactoryBot.create(:app_preference, collection: zoo_collection, name: "no_loan_requests", pref_type: :boolean, value: "0")
    end

    it 'syncs enabled no_loan_requests preferences to collections' do
      post app_prefs_path, params: {
        app_prefs: {
          mpabi_collection.id => {
            no_loan_requests: "1"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(mpabi_collection.reload.no_loan_requests).to be true
      expect(zoo_collection.reload.no_loan_requests).to be false
    end

    it 'syncs unchecked no_loan_requests preferences to false on collections' do
      mpabi_collection.update!(no_loan_requests: true)
      zoo_collection.update!(no_loan_requests: true)

      post app_prefs_path, params: {
        app_prefs: {
          zoo_collection.id => {
            no_loan_requests: "1"
          }
        }
      }

      expect(response).to redirect_to(app_prefs_path)
      expect(mpabi_collection.reload.no_loan_requests).to be false
      expect(zoo_collection.reload.no_loan_requests).to be true
    end
  end
end

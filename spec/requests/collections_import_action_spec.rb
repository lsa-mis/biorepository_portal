require 'rails_helper'

RSpec.describe Collection, type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:collection) { FactoryBot.create(:collection) }
  let(:csv_file) { Tempfile.new(['occurrence', '.csv']).tap { |file| file.write("occurrenceID\n"); file.flush } }
  let(:upload) { Rack::Test::UploadedFile.new(csv_file.path, 'text/csv', original_filename: 'occurrence.csv') }

  after { csv_file.close! }

  def login_with_groups(super_admin:, admin:)
    uniqname = get_uniqname(user.email)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(super_admin)
    allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(admin)
    mock_login(user)
  end

  context 'import action' do
    it 'runs the import for a super admin' do
      login_with_groups(super_admin: true, admin: false)
      expect(ItemImportService).to receive(:new).and_call_original

      post import_collections_path, params: { collection_id: collection.id, files: [upload] }

      expect(response).to redirect_to(collection_path(collection))
      expect(flash[:notice]).to eq("Import finished successfully.")
    end

    it 'does not run the import for a collection admin' do
      login_with_groups(super_admin: false, admin: true)
      expect(ItemImportService).not_to receive(:new)

      post import_collections_path, params: { collection_id: collection.id, files: [upload] }

      expect(response).to have_http_status(:redirect)
    end
  end
end

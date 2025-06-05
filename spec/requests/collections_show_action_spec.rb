require 'rails_helper'


RSpec.describe Collection, type: :request do

  context 'show action' do

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }
      before do
        uniqname = get_uniqname(super_admin_user.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end
      it 'should display Delete Collection button on the show page' do
          get collection_path(collection)
          expect(response.body).to include("Delete Collection")
      end
      it 'should display import button on the show page' do
        get collection_path(collection)
        expect(response.body).to include("Import")
      end
    end

  end 

  context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-super-admins").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'should not display Delete Collection but should display Edit Collection button on the show page' do
        get collection_path(collection)
        expect(response.body).not_to include("Delete Collection")
        expect(response.body).to include("Edit Collection")
      end

      it 'should display import button on the show page' do
        get collection_path(collection)
        expect(response.body).to include("Import")
      end
  end

  context 'with user role' do
    let!(:collection) { FactoryBot.create(:collection) }

    it 'should display collection details on the show page' do
      get collection_path(collection)
      expect(response.body).to include(collection.division)
    end
    it 'should not display Delete Collection or Edit Collection buttons on the show page' do
      get collection_path(collection)
      expect(response.body).not_to include("Delete Collection")
      expect(response.body).not_to include("Edit Collection")
    end

    it 'should not display import button on the show page' do
      get collection_path(collection)
      expect(response.body).not_to include("Import")
    end
  end
end 
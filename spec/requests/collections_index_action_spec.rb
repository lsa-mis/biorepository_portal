require 'rails_helper'

SUPER_ADMIN_LDAP_GROUP = "lsa-biorepository-super-admins"

RSpec.describe Collection, type: :request do

  context 'index action' do

    context 'when not logged in' do
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        # Ensure the user is not logged in
        get collections_path
      end

      it 'should display collections but not the New Collections button for visitors' do
        expect(response).to have_http_status(200)
        expect(response.body).not_to include("New Collection")
      end
    end

    context 'with authenticated user' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }
      before do
        uniqname = get_uniqname(user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(user)
      end

      it 'should display collections but not the New Collections button for authenticated users' do
        get collections_path
        expect(response).to have_http_status(200)
        expect(response.body).not_to include("New Collection")
      end
    end

    context 'with developer role' do
      let!(:developer) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }
      before do
        uniqname = get_uniqname(developer.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(developer)
      end

      it 'returns 200' do
        get collections_path
        expect(response).to have_http_status(200)
      end
    end

    context 'with developer role' do
      let!(:developer) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(developer.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(developer)
      end

      it 'should display Create Preferences link in the nav bar' do
        get collections_path
        expect(response.body).to include("Create Preferences")
      end
    end


    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }
      before do
        uniqname = get_uniqname(super_admin_user.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'returns 200' do
        get collections_path
        expect(response).to have_http_status(200)
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'returns 200' do
        get collections_path
        expect(response).to have_http_status(200)
      end
    end

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(super_admin_user.email)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'should display New Collection button on the index page' do
        get collections_path
        expect(response.body).to include("New Collection")
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:collection) { FactoryBot.create(:collection) }

      before do
        uniqname = get_uniqname(admin_user.email)
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, "lsa-biorepository-developers").and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, collection.admin_group).and_return(true)
        mock_login(admin_user)
      end

      it 'should not display New Collection button on the index page' do
        collections_path
        expect(response.body).not_to include("New Collection")

      end
    end

  end
end

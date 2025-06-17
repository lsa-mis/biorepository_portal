require 'rails_helper'
SUPER_ADMIN_LDAP_GROUP = "lsa-biorepository-super-admins"

RSpec.describe Collection, type: :request do
  subject {
    described_class.new(
      admin_group: "admin_group",
      division: "division",
      division_page_url: "http://example.com",
      link_to_policies: "http://example.com/policies",
      short_description: "Short description",
      long_description: "Long description"
    )
  }

  describe "validations for admin group and division" do
    described_class.create!(
      admin_group: "not_admin_group",
      division: "different_division",
      division_page_url: "http://example.com",
      link_to_policies: "http://example.com/policies",
      short_description: "Short description",
      long_description: "Long description"
    )
    it "is valid with non-duplicate admin group and division" do
      expect(subject).to be_valid
    end

    it "is not valid without an admin group" do
      subject.admin_group = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:admin_group]).to include("can't be blank")
    end

    it "is not valid without a division" do
      subject.division = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:division]).to include("can't be blank")
    end

    it "is not valid with a duplicate admin group" do
      described_class.create!(
        admin_group: "admin_group", 
        division: "good division", 
        division_page_url: "http://example.com", 
        link_to_policies: "http://example.com/policies", 
        short_description: "Short description", 
        long_description: "Long description"
      )
      expect(subject).not_to be_valid
      expect(subject.errors[:admin_group]).to include("has already been taken")
    end

    it "is not valid with a duplicate division" do
      described_class.create!(
        admin_group: "another_admin_group", 
        division: "division", 
        division_page_url: "http://example.com", 
        link_to_policies: "http://example.com/policies", 
        short_description: "Short description", 
        long_description: "Long description"
      )
      expect(subject).not_to be_valid
      expect(subject.errors[:division]).to include("has already been taken")
    end
  end

  # Validations for Policies, URLs, and Descriptions
  describe "validations for other fields" do
    it "is not valid without a short description" do
      subject.short_description = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:short_description]).to include("can't be blank")
    end

    it "is not valid without a long description" do
      subject.long_description = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:long_description]).to include("can't be blank")
    end

    it "is not valid without a division page URL" do
      subject.division_page_url = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:division_page_url]).to include("can't be blank")
    end

    it "is not valid without a link to policies" do
      subject.link_to_policies = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:link_to_policies]).to include("can't be blank")
    end

    it "is valid with all required fields" do
      expect(subject).to be_valid
    end
  end
end

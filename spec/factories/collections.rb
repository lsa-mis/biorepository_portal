# == Schema Information
#
# Table name: collections
#
#  id                :bigint           not null, primary key
#  admin_group       :string
#  description       :text
#  division          :string
#  division_page_url :string
#  link_to_policies  :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :collection do
    division { "MPABI" }
    admin_group { "admin_group" }
    # description { "MyText" }
    # division_page_url { "MyString" }
    # link_to_policies { "MyString" }
  end
end

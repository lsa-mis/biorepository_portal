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
class Collection < ApplicationRecord
end

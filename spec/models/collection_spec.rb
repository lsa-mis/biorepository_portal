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
require 'rails_helper'

RSpec.describe Collection, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

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
  has_many :items, dependent: :destroy
  has_one_attached :image
  def self.ransackable_attributes(auth_object = nil)
    ["admin_group", "created_at", "description", "division", "division_page_url", "id", "id_value", "link_to_policies", "updated_at"]
  end
end


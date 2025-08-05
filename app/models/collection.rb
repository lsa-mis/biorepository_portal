# == Schema Information
#
# Table name: collections
#
#  id                :bigint           not null, primary key
#  admin_group       :string
#  division          :string
#  division_page_url :string
#  link_to_policies  :string
#  short_description :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_collections_on_division  (division)
#
class Collection < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :collection_questions, dependent: :destroy
  has_rich_text :long_description
  has_one_attached :image

  validates :admin_group, presence: true, uniqueness: true
  validates :division, presence: true, uniqueness: true
  validates :division_page_url, presence: true
  validates :link_to_policies, presence: true
  validates :short_description, presence: true
  validates :long_description, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["admin_group", "created_at", "description", "division", "division_page_url", "id", "id_value", "link_to_policies", "updated_at"]
  end
end


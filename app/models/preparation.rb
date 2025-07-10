# == Schema Information
#
# Table name: preparations
#
#  id          :bigint           not null, primary key
#  barcode     :string
#  count       :integer
#  description :string
#  prep_type   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  item_id     :bigint           not null
#
# Indexes
#
#  index_preparations_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id) ON DELETE => cascade
#
class Preparation < ApplicationRecord
  belongs_to :item
  has_many :requestables
  has_many :checkouts, through: :requestables

  def display_name
    display_name = "#{self.prep_type}"
    if self.description.present?
      display_name += " - #{self.description}"
    end
    display_name
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[description prep_type]
  end

  def self.ransackable_associations(auth_object = nil)
    [ :item ]
  end
end

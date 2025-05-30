# == Schema Information
#
# Table name: identifications
#
#  id                         :bigint           not null, primary key
#  class_name                 :string
#  current                    :boolean          default(FALSE), not null
#  date_identified            :string
#  family                     :string
#  genus                      :string
#  identification_remarks     :text
#  identified_by              :string
#  infraspecific_epithet      :string
#  kingdom                    :string
#  order_name                 :string
#  phylum                     :string
#  scientific_name            :string
#  scientific_name_authorship :string
#  specific_epithet           :string
#  taxon_rank                 :string
#  type_status                :string
#  vernacular_name            :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  item_id                    :bigint           not null
#
# Indexes
#
#  index_identifications_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class Identification < ApplicationRecord
  belongs_to :item

  def self.ransackable_attributes(auth_object = nil)
    [
      "class_name", "date_identified", "family", "genus", "identification_remarks",
      "identified_by", "infraspecific_epithet", "kingdom", "order_name",
      "phylum", "scientific_name", "scientific_name_authorship",
      "specific_epithet", "taxon_rank", "type_status", "vernacular_name"
    ]
  end
  
  def self.ransackable_associations(auth_object = nil)
    [ :item ]
  end
end

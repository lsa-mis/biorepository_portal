# == Schema Information
#
# Table name: identifications
#
#  id                         :bigint           not null, primary key
#  class_name                 :string
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
#  taxon_rank                 :integer
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
end

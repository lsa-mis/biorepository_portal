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
#  fk_rails_...  (item_id => items.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :identification do
    type_status { "MyString" }
    identified_by { "MyString" }
    date_identified { "MyString" }
    identification_remarks { "MyText" }
    scientific_name { "MyString" }
    scientific_name_authorship { "MyString" }
    kingdom { "MyString" }
    phylum { "MyString" }
    class_name { "MyString" }
    order_name { "MyString" }
    family { "MyString" }
    genus { "MyString" }
    specific_epithet { "MyString" }
    infraspecific_epithet { "MyString" }
    taxon_rank { 1 }
    vernacular_name { "MyString" }
    item { nil }
  end
end

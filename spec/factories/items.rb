# == Schema Information
#
# Table name: items
#
#  id                               :bigint           not null, primary key
#  associated_sequences             :string
#  catalog_number                   :string
#  continent                        :string
#  coordinate_uncertainty_in_meters :float
#  country                          :string
#  county                           :string
#  decimal_latitude                 :float
#  decimal_longitude                :float
#  event_date_end                   :date
#  event_date_start                 :date
#  event_remarks                    :text
#  field_number                     :string
#  geodetic_datum                   :string
#  georeference_protocol            :string
#  georeferenced_by                 :string
#  georeferenced_date               :date
#  individual_count                 :integer
#  life_stage                       :string
#  locality                         :string
#  maximum_elevation_in_meters      :float
#  minimum_elevation_in_meters      :float
#  modified                         :date
#  occurrence_remarks               :text
#  organism_remarks                 :text
#  other_catalog_numbers            :string
#  recorded_by                      :string
#  reproductive_condition           :string
#  sampling_protocol                :string
#  sex                              :string
#  state_province                   :string
#  verbatim_coordinates             :string
#  verbatim_elevation               :string
#  verbatim_event_date              :string
#  verbatim_locality                :string
#  vitality                         :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  collection_id                    :bigint           not null
#  occurrence_id                    :string
#
# Indexes
#
#  index_items_on_collection_id  (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
FactoryBot.define do
  factory :item do
    occurrence_id { "MyString" }
    catalog_number { "MyString" }
    modified { "2025-05-13" }
    recorded_by { "MyString" }
    individual_count { 1 }
    sex { "MyString" }
    life_stage { "MyString" }
    reproductive_condition { "MyString" }
    vitality { "MyString" }
    other_catalog_numbers { "MyString" }
    occurrence_remarks { "MyText" }
    organism_remarks { "MyText" }
    associated_sequences { "MyString" }
    field_number { "MyString" }
    event_date_start { "2025-05-13" }
    event_date_end { "2025-05-13" }
    verbatim_event_date { "MyString" }
    sampling_protocol { "MyString" }
    event_remarks { "MyText" }
    continent { "MyString" }
    country { "MyString" }
    state_province { "MyString" }
    county { "MyString" }
    locality { "MyString" }
    verbatim_locality { "MyString" }
    verbatim_elevation { "MyString" }
    minimum_elevation_in_meters { 1.5 }
    maximum_elevation_in_meters { 1.5 }
    decimal_latitude { 1.5 }
    decimal_longitude { 1.5 }
    coordinate_uncertainty_in_meters { 1.5 }
    verbatim_coordinates { "MyString" }
    georeferenced_by { "MyString" }
    georeferenced_date { "2025-05-13" }
    geodetic_datum { "MyString" }
    georeference_protocol { "MyString" }
    archived { false }
    collection { nil }
  end
end

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
#  index_items_on_catalog_number  (catalog_number)
#  index_items_on_collection_id   (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
FactoryBot.define do
  factory :item do
    catalog_number { "SEED-#{SecureRandom.hex(6).upcase}" }
    continent { ["Africa", "Antarctica", "Asia", "Europe", "North America", "Oceania", "South America"].sample }
    country { Faker::Address.country }
    county { Faker::Address.city }
    state_province { Faker::Address.state }
    locality { Faker::Address.street_name }
    decimal_latitude { rand(-90.0..90.0).round(6) }
    decimal_longitude { rand(-180.0..180.0).round(6) }
    event_date_start { Faker::Date.backward(days: 3650) }
    event_date_end { Faker::Date.backward(days: 365) }
    recorded_by { Faker::Name.name }
    individual_count { rand(1..20) }
    life_stage { ["juvenile", "adult"].sample }
    sex { ["male", "female"].sample }
    vitality { ["alive", "dead"].sample }
    sampling_protocol { Faker::Lorem.words(number: 3).join(" ") }
    occurrence_remarks { Faker::Lorem.sentence }
    occurrence_id { Faker::Alphanumeric.unique.alphanumeric(number: 20).downcase }
    collection { nil }
  end
end

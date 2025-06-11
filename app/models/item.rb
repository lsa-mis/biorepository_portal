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
class Item < ApplicationRecord
  belongs_to :collection
  has_many :identifications, dependent: :destroy
  has_many :preparations, dependent: :destroy

  def display_name
    # Placeholder for displaying the item name
    "#{Identification.find_by(item_id: self.id, current: true)&.scientific_name} - #{Identification.find_by(item_id: self.id, current: true)&.vernacular_name} - #{self.country} - #{self.event_date_start}"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["archived", "associated_sequences", "catalog_number", "collection_id", "continent", "coordinate_uncertainty_in_meters",
    "country", "county", "created_at", "decimal_latitude", "decimal_longitude", "event_date_end", "event_date_start", "event_remarks",
    "field_number", "geodetic_datum", "georeference_protocol", "georeferenced_by", "georeferenced_date", "id", "individual_count",
    "life_stage", "locality", "maximum_elevation_in_meters", "minimum_elevation_in_meters", "modified", "occurrence_id",
    "occurrence_remarks", "organism_remarks", "other_catalog_numbers", "recorded_by", "reproductive_condition", "sampling_protocol",
    "sex", "state_province", "updated_at", "verbatim_coordinates", "verbatim_elevation", "verbatim_event_date", "verbatim_locality", "vitality"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "collection", "identifications", "preparations" ]
  end

end

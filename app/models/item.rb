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
  has_one :current_identification, -> { where(current: true) }, class_name: 'Identification', foreign_key: 'item_id'
  has_many :preparations, dependent: :destroy
  has_many :unavailables
  has_many :checkouts, through: :unavailables

  def name
    name = ""
    name = self.catalog_number + " - " if self.catalog_number.present?
    name += "#{current_identification&.scientific_name&.humanize}"
    if current_identification&.vernacular_name.present?
      name += " [#{current_identification&.vernacular_name.humanize}]"
    end
    name
  end

  def display_name
    display_name = self.name
    display_name += " - " + self.preparations.map(&:display_name).join(", ") if self.preparations.any?
    display_name
  end

  def coordinates
    if self.decimal_latitude.present? && self.decimal_longitude.present?
      "#{self.decimal_latitude}, #{self.decimal_longitude}"
    else
      "Coordinates not available"
    end
  end

  ransacker :country_case_insensitive, type: :string do
    Arel.sql('lower(items.country)')
  end

  ransacker :state_province_case_insensitive, type: :string do
    Arel.sql('lower(items.state_province)')
  end
  
  ransacker :sex_case_insensitive, type: :string do
    Arel.sql('lower(items.sex)')
  end

  ransacker :continent_case_insensitive, type: :string do
    Arel.sql('lower(items.continent)')
  end

  def self.ransackable_attributes(auth_object = nil)
    ["associated_sequences", "catalog_number", "collection_id", "continent_case_insensitive", "coordinate_uncertainty_in_meters",
    "country_case_insensitive", "county", "created_at", "decimal_latitude", "decimal_longitude", "event_date_end", "event_date_start", "event_remarks",
    "field_number", "geodetic_datum", "georeference_protocol", "georeferenced_by", "georeferenced_date", "id", "individual_count",
    "life_stage", "locality", "maximum_elevation_in_meters", "minimum_elevation_in_meters", "modified", "occurrence_id",
    "occurrence_remarks", "organism_remarks", "other_catalog_numbers", "recorded_by", "reproductive_condition", "sampling_protocol",
    "sex_case_insensitive", "state_province_case_insensitive", "updated_at", "verbatim_coordinates", "verbatim_elevation", "verbatim_event_date", "verbatim_locality", "vitality"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "collection", "current_identification", "identifications", "preparations" ]
  end

end

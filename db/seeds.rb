# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


fields = MapField.create!([
{table: "items", specify_field: "occurrenceID", rails_field: "occurrence_id", caption: ""},
{table: "items", specify_field: "Sensitive Filter - DO NOT MAP", rails_field: "filter_ignore", caption: ""},
{table: "items", specify_field: "catalogNumber", rails_field: "catalog_number", caption: ""},
{table: "items", specify_field: "modified", rails_field: "modified", caption: ""},
{table: "items", specify_field: "recordedBy", rails_field: "recorded_by", caption: "Collector"},
{table: "items", specify_field: "individualCount", rails_field: "individual_count", caption: "# of Samples/Specimens"},
{table: "items", specify_field: "sex", rails_field: "sex", caption: "Gender"},
{table: "items", specify_field: "lifeStage", rails_field: "life_stage", caption: ""},
{table: "items", specify_field: "reproductiveCondition", rails_field: "reproductive_condition", caption: ""},
{table: "items", specify_field: "vitality", rails_field: "vitality", caption: ""},
{table: "preparations", specify_field: "preparations", rails_field: "preparations", caption: ""},
{table: "items", specify_field: "otherCatalogNumbers", rails_field: "other_catalog_numbers", caption: ""},
{table: "items", specify_field: "occurrenceRemarks", rails_field: "occurrence_remarks", caption: ""},
{table: "items", specify_field: "organismRemarks", rails_field: "organism_remarks", caption: ""},
{table: "items", specify_field: "associatedSequences", rails_field: "associated_sequences", caption: ""},
{table: "items", specify_field: "fieldNumber", rails_field: "field_number", caption: ""},
{table: "items", specify_field: "year", rails_field: "year_ignore", caption: ""},
{table: "items", specify_field: "month", rails_field: "month_ignore", caption: ""},
{table: "items", specify_field: "day", rails_field: "day_ignore", caption: ""},
{table: "items", specify_field: "eventDate", rails_field: "event_date", caption: ""},
{table: "items", specify_field: "verbatimEventDate", rails_field: "verbatim_event_date", caption: ""},
{table: "items", specify_field: "samplingProtocol", rails_field: "sampling_protocol", caption: ""},
{table: "items", specify_field: "eventRemarks", rails_field: "event_remarks", caption: ""},
{table: "items", specify_field: "continent", rails_field: "continent", caption: ""},
{table: "items", specify_field: "country", rails_field: "country", caption: ""},
{table: "items", specify_field: "stateProvince", rails_field: "state_province", caption: ""},
{table: "items", specify_field: "county", rails_field: "county", caption: ""},
{table: "items", specify_field: "locality", rails_field: "locality", caption: ""},
{table: "items", specify_field: "verbatimLocality", rails_field: "verbatim_locality", caption: ""},
{table: "items", specify_field: "verbatimElevation", rails_field: "verbatim_elevation", caption: ""},
{table: "items", specify_field: "minimumElevationInMeters", rails_field: "maximum_elevation_in_meters", caption: ""},
{table: "items", specify_field: "maximumElevationInMeters", rails_field: "minimum_elevation_in_meters", caption: ""},
{table: "items", specify_field: "decimalLatitude", rails_field: "decimal_latitude", caption: ""},
{table: "items", specify_field: "decimalLongitude", rails_field: "decimal_longitude", caption: ""},
{table: "items", specify_field: "coordinateUncertaintyInMeters", rails_field: "coordinate_uncertainty_in_meters", caption: ""},
{table: "items", specify_field: "verbatimCoordinates", rails_field: "verbatim_coordinates", caption: ""},
{table: "items", specify_field: "georeferencedBy", rails_field: "georeferenced_by", caption: ""},
{table: "items", specify_field: "georeferencedDate", rails_field: "georeferenced_date", caption: ""},
{table: "items", specify_field: "geodeticDatum", rails_field: "geodetic_datum", caption: ""},
{table: "items", specify_field: "georeferenceProtocol", rails_field: "georeference_protocol", caption: ""},
{table: "identifications", specify_field: "occurrenceID", rails_field: "occurrence_id_ignore", caption: ""},
{table: "identifications", specify_field: "catalogNumber", rails_field: "catalog_number_ignore", caption: ""},
{table: "identifications", specify_field: "isCurrent", rails_field: "current", caption: ""},
{table: "identifications", specify_field: "typeStatus", rails_field: "type_status", caption: ""},
{table: "identifications", specify_field: "identifiedBy", rails_field: "identified_by", caption: ""},
{table: "identifications", specify_field: "dateIdentified", rails_field: "date_identified", caption: ""},
{table: "identifications", specify_field: "identificationRemarks", rails_field: "identification_remarks", caption: ""},
{table: "identifications", specify_field: "scientificName", rails_field: "scientific_name", caption: ""},
{table: "identifications", specify_field: "scientificNameAuthorship", rails_field: "scientific_name_authorship", caption: ""},
{table: "identifications", specify_field: "kingdom", rails_field: "kingdom", caption: ""},
{table: "identifications", specify_field: "phylum", rails_field: "phylum", caption: ""},
{table: "identifications", specify_field: "class", rails_field: "class_name", caption: ""},
{table: "identifications", specify_field: "order", rails_field: "order_name", caption: ""},
{table: "identifications", specify_field: "family", rails_field: "family", caption: ""},
{table: "identifications", specify_field: "genus", rails_field: "genus", caption: ""},
{table: "identifications", specify_field: "specificEpithet", rails_field: "specific_epithet", caption: ""},
{table: "identifications", specify_field: "infraspecificEpithet", rails_field: "infraspecific_epithet", caption: ""},
{table: "identifications", specify_field: "taxonRank", rails_field: "taxon_rank", caption: ""},
{table: "identifications", specify_field: "vernacularName", rails_field: "vernacular_name", caption: "Common Name"},
{table: "collections", specify_field: "mpabi_processed_identifications", rails_field: "MPABI", caption: ""},
{table: "collections", specify_field: "mpabi_processed_occurrence", rails_field: "MPABI", caption: ""},
{table: "collections", specify_field: "herpetology_t_processed_occurrence", rails_field: "Herpetology Tissue", caption: ""},
{table: "collections", specify_field: "mamals_t_processed_occurrence", rails_field: "Mamals Tissue", caption: ""},
{table: "collections", specify_field: "mamals_t_processed_identifications", rails_field: "Mamals Tissue", caption: ""},
{table: "collections", specify_field: "mpabi", rails_field: "MPABI", caption: ""},
])

locations = [
  "about",
  "collections_index",
  "collection_show",
  "app_preferences",
  "checkout",
  "loan_request",
  "information_request",
  "faq",
  "loan_questions",
  "collection_questions",
  "saved_searches"
]

locations.each do |loc|
  Announcement.find_or_create_by!(location: loc) do |a|
    a.content = "Default announcement for #{loc.humanize}"
  end
end

# collections = Collection.create!([
#   { division: "MPABI" },
#   { division: "Mammals Tissue" },
#   { division: "Herpetology Tissue" }
# ])
# ============================================================
# PERFORMANCE TEST DATA (added by Rishika, May 2026)
# Adds 1,000,000 fake Items, each with 1 Preparation and
# 1 Identification — matching real BioRepo data structure.
# Safe to run on localhost and staging ONLY — never production.
#
# How it works:
#   - Runs 1,000 loops (batches)
#   - Each batch inserts 1,000 Items, 1,000 Preparations,
#     and 1,000 Identifications
#   - 1,000 batches × 1,000 = 1,000,000 records per table
#
# To remove fake records later:
#   Item.where("catalog_number LIKE 'SEED-%'").each(&:destroy)
# ============================================================

require 'faker'

puts "Starting seed — 1,000,000 items with preparations and identifications..."
puts "This will take roughly 30-45 minutes. Progress shown every 1,000 records."

CONTINENTS  = ["Africa", "Antarctica", "Asia", "Europe", "North America", "Oceania", "South America"]
COUNTRIES   = ["United States", "Canada", "Mexico", "Brazil", "Germany", "Kenya", "Australia", "Japan", "India", "France"]
LIFE_STAGES = ["adult", "juvenile", "larva", "egg", "pupa"]
SEXES       = ["male", "female", "unknown"]
PREP_TYPES  = ["skin", "skull", "skeleton", "fluid", "tissue", "whole"]
KINGDOMS    = ["Animalia", "Plantae", "Fungi"]
PHYLUMS     = ["Chordata", "Arthropoda", "Mollusca", "Magnoliophyta"]
CLASSES     = ["Mammalia", "Aves", "Reptilia", "Amphibia", "Insecta"]
ORDERS      = ["Carnivora", "Primates", "Rodentia", "Passeriformes", "Squamata"]
FAMILIES    = ["Felidae", "Canidae", "Accipitridae", "Colubridae", "Muridae"]
TAXON_RANKS = ["species", "subspecies", "variety"]
TYPE_STATUS = ["holotype", "paratype", "syntype", nil]

COLLECTION_IDS = Collection.pluck(:id)

batch_size = 1_000
total      = 1_000_000
batches    = total / batch_size

batches.times do |i|
  now = Time.current

  # STEP 1 — build and insert 1,000 Items
  items_data = batch_size.times.map do
    {
      catalog_number:     "SEED-#{SecureRandom.hex(6).upcase}",
      collection_id:      COLLECTION_IDS.sample,
      continent:          CONTINENTS.sample,
      country:            COUNTRIES.sample,
      county:             Faker::Address.city,
      state_province:     Faker::Address.state,
      locality:           Faker::Address.street_name,
      decimal_latitude:   rand(-90.0..90.0).round(6),
      decimal_longitude:  rand(-180.0..180.0).round(6),
      event_date_start:   Faker::Date.backward(days: 3650),
      event_date_end:     Faker::Date.backward(days: 365),
      recorded_by:        Faker::Name.name,
      individual_count:   rand(1..20),
      life_stage:         LIFE_STAGES.sample,
      sex:                SEXES.sample,
      vitality:           ["alive", "dead"].sample,
      sampling_protocol:  Faker::Lorem.words(number: 3).join(" "),
      occurrence_remarks: Faker::Lorem.sentence,
      created_at:         now,
      updated_at:         now
    }
  end
  Item.insert_all(items_data)

  # STEP 2 — fetch IDs of items just inserted
  item_ids = Item.where("catalog_number LIKE 'SEED-%'")
                 .order(id: :desc)
                 .limit(batch_size)
                 .pluck(:id)

  # STEP 3 — insert 1 Preparation per item
  preparations_data = item_ids.map do |item_id|
    {
      item_id:     item_id,
      barcode:     "BAR-#{SecureRandom.hex(5).upcase}",
      count:       rand(1..10),
      prep_type:   PREP_TYPES.sample,
      description: Faker::Lorem.sentence,
      created_at:  now,
      updated_at:  now
    }
  end
  Preparation.insert_all(preparations_data)

  # STEP 4 — insert 1 Identification per item
  genus   = Faker::Creature::Animal.name.split.first.capitalize
  species = Faker::Lorem.word.downcase

  identifications_data = item_ids.map do |item_id|
    {
      item_id:                    item_id,
      current:                    true,
      kingdom:                    KINGDOMS.sample,
      phylum:                     PHYLUMS.sample,
      class_name:                 CLASSES.sample,
      order_name:                 ORDERS.sample,
      family:                     FAMILIES.sample,
      genus:                      genus,
      specific_epithet:           species,
      scientific_name:            "#{genus} #{species}",
      scientific_name_authorship: Faker::Name.last_name,
      taxon_rank:                 TAXON_RANKS.sample,
      type_status:                TYPE_STATUS.sample,
      identified_by:              Faker::Name.name,
      date_identified:            Faker::Date.backward(days: 1825),
      vernacular_name:            Faker::Creature::Animal.name,
      identification_remarks:     Faker::Lorem.sentence,
      created_at:                 now,
      updated_at:                 now
    }
  end
  Identification.insert_all(identifications_data)

  puts "Batch #{i + 1}/#{batches} done — #{((i + 1) * batch_size).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} items, preparations & identifications inserted"
end

puts ""
puts "========================================"
puts "Seed complete!"
puts "Items:           #{Item.count}"
puts "Preparations:    #{Preparation.count}"
puts "Identifications: #{Identification.count}"
puts "========================================"
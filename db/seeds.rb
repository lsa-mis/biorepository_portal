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
  "faq",
  "loan_questions",
  "collection_questions",
  "todo"
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

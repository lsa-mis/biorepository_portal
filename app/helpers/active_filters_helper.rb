module ActiveFiltersHelper
  DYNAMIC_FIELD_LABELS = {
  "identifications_scientific_name_i_cont_any" => "Scientific Name",
  "identifications_vernacular_name_i_cont_any" => "Common Name",
  "preparations_prep_type_i_cont_any"          => "Preparation Type",
  "preparations_description_i_cont_any"        => "Preparation Description",
  "associated_sequences_i_cont_any"            => "Associated Sequences",
  "catalog_number_eq_any"                      => "Catalog Number",
  "identifications_class_name_case_insensitive_cont_any"  => "Class",
  "country_case_insensitive_cont_any"          => "Country or Region",
  "county_i_cont_any"                          => "County",
  "event_remarks_i_cont_any"                   => "Event Remarks",
  "identifications_family_case_insensitive_cont_any"     => "Family",
  "field_number_i_cont_any"                    => "Field Number",
  "identifications_genus_case_insensitive_cont_any"      => "Genus",
  "geodetic_datum_i_cont_any"                  => "Geodetic Datum",
  "georeference_protocol_i_cont_any"           => "Georeference Protocol",
  "georeferenced_by_i_cont_any"                => "Georeferenced By",
  "life_stage_i_cont_any"                      => "Life Stage",
  "locality_i_cont_any"                        => "Locality",
  "occurrence_remarks_i_cont_any"              => "Occurrence Remarks",
  "identifications_order_name_case_insensitive_cont_any" => "Order",
  "organism_remarks_i_cont_any"                => "Organism Remarks",
  "other_catalog_numbers_i_cont_any"           => "Other Catalog Numbers",
  "identifications_phylum_case_insensitive_cont_any"     => "Phylum",
  "recorded_by_i_cont_any"                     => "Recorded By",
  "reproductive_condition_i_cont_any"          => "Reproductive Condition",
  "sampling_protocol_i_cont_any"               => "Sampling Protocol",
  "sex_case_insensitive_cont_any"              => "Sex",
  "state_province_case_insensitive_cont_any"   => "State / Province",
  "verbatim_coordinates_i_cont_any"            => "Verbatim Coordinates",
  "verbatim_elevation_i_cont_any"              => "Verbatim Elevation",
  "verbatim_event_date_i_cont_any"             => "Verbatim Event Date",
  "verbatim_locality_i_cont_any"               => "Verbatim Locality",
  "vitality_i_cont_any"                        => "Vitality"
  }.freeze

  STANDARD_FILTER_LABELS = {
    "continent_case_insensitive_in" => "Continent",
    "country_case_insensitive_in" => "Country or Region",
    "state_province_case_insensitive_in" => "State/Province",
    "sex_case_insensitive_in" => "Sex",
    "identifications_kingdom_case_insensitive_in" => "Kingdom",
    "identifications_phylum_case_insensitive_in" => "Phylum",
    "identifications_class_name_case_insensitive_in" => "Class",
    "identifications_order_name_case_insensitive_in" => "Order",
    "identifications_family_case_insensitive_in" => "Family",
    "identifications_genus_case_insensitive_in" => "Genus",
    "event_date_start_gteq" => "Event Date Start (After)",
    "event_date_end_lteq" => "Event Date End (Before)",
    "minimum_elevation_in_meters_gteq" => "Min Elevation",
    "maximum_elevation_in_meters_lteq" => "Max Elevation",
    "decimal_latitude_eq" => "Latitude",
    "decimal_longitude_eq" => "Longitude"
  }.freeze

  def format_active_filters(dynamic_fields: nil)

    filters_array = []
    # Handle dynamic fields
    if dynamic_fields.present?
      dynamic_fields.each do |group|
        str = []
        group_hash = {}
        group.each do |field_hash|
          label = DYNAMIC_FIELD_LABELS[field_hash[:field]] || field_hash[:field].titleize
          str << Array.wrap(field_hash[:value])
          group_hash[field_hash[:field]] = {label => field_hash[:value]}
        end
        filters_array << group_hash
      end
    end

    # Handle standard filters
    if params[:q].present?
      params[:q].each do |key, value|
        next if value.blank? || key == "groupings" # Skip empty values and the "groupings" key
        if key == "collection_id_in"
          collection_names = Collection.where(id: value).pluck(:division)
          
          # Create nested hash structure for all collections
          collection_hashes = {}
          Array.wrap(value).each_with_index do |collection_id, index|
            collection_key = "collection_#{collection_id}"
            collection_name = collection_names[index] || "Unknown Collection"
            collection_hashes[collection_key] = collection_name
          end
          filters_array << {key => collection_hashes}
          next
        end
        label = STANDARD_FILTER_LABELS[key] || key.titleize
        filters_array << {key => { label => value }}
      end
    end
    filters_array
  end

  def or_separator(index, total)
    index == total - 1 ? "" : content_tag(:span, " OR ", class: "fw-bold")
  end

end

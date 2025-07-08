module ActiveFiltersHelper
  DYNAMIC_FIELD_LABELS = {
  "associated_sequences_i_cont"      => "Associated Sequences",
  "catalog_number_eq"                => "Catalog Number",
  "county_i_cont"                    => "County",
  "event_remarks_i_cont"            => "Event Remarks",
  "field_number_i_cont"             => "Field Number",
  "geodetic_datum_i_cont"           => "Geodetic Datum",
  "georeference_protocol_i_cont"    => "Georeference Protocol",
  "georeferenced_by_i_cont"         => "Georeferenced By",
  "life_stage_i_cont"               => "Life Stage",
  "locality_i_cont"                 => "Locality",
  "occurrence_remarks_i_cont"       => "Occurrence Remarks",
  "organism_remarks_i_cont"         => "Organism Remarks",
  "other_catalog_numbers_i_cont"    => "Other Catalog Numbers",
  "recorded_by_i_cont"              => "Recorded By",
  "reproductive_condition_i_cont"   => "Reproductive Condition",
  "sampling_protocol_i_cont"        => "Sampling Protocol",
  "verbatim_coordinates_i_cont"     => "Verbatim Coordinates",
  "verbatim_elevation_i_cont"       => "Verbatim Elevation",
  "verbatim_event_date_i_cont"      => "Verbatim Event Date",
  "verbatim_locality_i_cont"        => "Verbatim Locality",
  "vitality_i_cont"                 => "Vitality"
  }.freeze

  STANDARD_FILTER_LABELS = {
    "event_date_start_gteq" => "Event Date Start (After)",
    "event_date_end_lteq" => "Event Date End (Before)",
    "georeferenced_date_eq" => "Georeferenced Date",
    "modified_eq" => "Date Modified",
    "coordinate_uncertainty_in_meters_lteq" => "Max Coord. Uncertainty",
    "individual_count_gteq" => "Minimum Individual Count",
    "minimum_elevation_in_meters_gteq" => "Min Elevation",
    "maximum_elevation_in_meters_lteq" => "Max Elevation",
    "decimal_latitude_eq" => "Latitude",
    "decimal_longitude_eq" => "Longitude"
  }.freeze

  def format_active_filters(params)
    return [] unless params[:q].present?

    q = params[:q]
    dynamic_fields = params[:dynamic_fields] || {}
    filters = []

    if q[:collection_id_in].present?
      collection_ids = Array.wrap(q[:collection_id_in])
      collection_names = Collection.where(id: collection_ids).pluck(:division)
      filters += collection_names.map { |name| "#{name}" }
    end

    used_dynamic_keys = []
    if dynamic_fields.present?

      dynamic_fields.each do |_, group|
        group.each do |_, field_hash|
          next if field_hash["field"].blank? || field_hash["value"].blank?
          filters << "#{DYNAMIC_FIELD_LABELS[field_hash['field']]}: #{field_hash['value'].humanize}"
          used_dynamic_keys << field_hash["field"]
        end
      end
    end

    keys_to_skip = %w[collection_id_in dynamic_fields groupings] + used_dynamic_keys

    q.each do |key, value|
      next if keys_to_skip.include?(key) || value.blank? || value.is_a?(Hash)

      if value.is_a?(Array)
        filters += value.map(&:capitalize)
      else
        filters << "#{STANDARD_FILTER_LABELS[key]}: #{value}"
      end
    end

    filters.uniq
    
  end
end

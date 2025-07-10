module ActiveFiltersHelper
  DYNAMIC_FIELD_LABELS = {
  "associated_sequences_i_cont_any"      => "Associated Sequences",
  "catalog_number_eq_any"                => "Catalog Number",
  "county_i_cont_any"                => "County",
  "event_remarks_i_cont_any"            => "Event Remarks",
  "field_number_i_cont_any"             => "Field Number",
  "geodetic_datum_i_cont_any"           => "Geodetic Datum",
  "georeference_protocol_i_cont_any"    => "Georeference Protocol",
  "georeferenced_by_i_cont_any"         => "Georeferenced By",
  "life_stage_i_cont_any"               => "Life Stage",
  "locality_i_cont_any"                 => "Locality",
  "occurrence_remarks_i_cont_any"       => "Occurrence Remarks",
  "organism_remarks_i_cont_any"         => "Organism Remarks",
  "other_catalog_numbers_i_cont_any"    => "Other Catalog Numbers",
  "recorded_by_i_cont_any"              => "Recorded By",
  "reproductive_condition_i_cont_any"   => "Reproductive Condition",
  "sampling_protocol_i_cont_any"        => "Sampling Protocol",
  "verbatim_coordinates_i_cont_any"     => "Verbatim Coordinates",
  "verbatim_elevation_i_cont_any"       => "Verbatim Elevation",
  "verbatim_event_date_i_cont_any"      => "Verbatim Event Date",
  "verbatim_locality_i_cont_any"        => "Verbatim Locality",
  "vitality_i_cont_any"                 => "Vitality"
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
    keys_to_skip = %w[collection_id_in groupings]

    if q[:collection_id_in].present?
      collection_ids = Array.wrap(q[:collection_id_in])
      collection_names = Collection.where(id: collection_ids).pluck(:division)
      filters += collection_names.map { |name| "#{name}" }
    end

    # Get all values for key 'value' recursively
    filters += extract_values_for_key(dynamic_fields, "value") if dynamic_fields.present?

    q.each do |key, value|
      next if keys_to_skip.include?(key) || value.blank? || value.is_a?(Hash)
      if value.is_a?(Array)
        filters += value.map(&:capitalize)
      else
        filters << "#{STANDARD_FILTER_LABELS[key]}: #{value}"
      end
    end
    filters.compact.uniq
  end

  def extract_values_for_key(obj, target_key)
    obj = obj.to_unsafe_h if obj.is_a?(ActionController::Parameters)
    results = []
    case obj
    when Hash
      obj.each do |k, v|
        if k.to_s == target_key.to_s
          results << v if v.present?
        else
          results.concat(extract_values_for_key(v, target_key))
        end
      end
    when Array
      obj.each { |v| results.concat(extract_values_for_key(v, target_key)) }
    end
    results
  end
  
end

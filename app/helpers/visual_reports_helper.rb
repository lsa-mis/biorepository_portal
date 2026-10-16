module VisualReportsHelper
  # Row labels for items with no value; they have no matching search filter, so they are not linked
  BLANK_LABELS = ["Unknown", "No preparation"].freeze

  # Search queries for count table rows. Each returns the ransack params that find the items counted
  # in that row (using the advanced search filter fields), or nil when the row can't be searched.

  def collection_search_query(division)
    ids = @collection_ids_by_division&.dig(division)
    { collection_id_in: ids } if ids.present?
  end

  def preparation_search_query(collection, preparation_type)
    return if BLANK_LABELS.include?(preparation_type)

    # Counts are grouped by division, so search every collection with this division
    { collection_id_in: @collection_ids_by_division&.dig(collection.division) || [collection.id],
      preparations_prep_type_case_insensitive_in: [preparation_type.downcase] }
  end

  def year_search_query(year)
    { event_date_start_gteq: "#{year}-01-01", event_date_start_lteq: "#{year}-12-31" }
  end

  def country_search_query(country)
    { country_case_insensitive_in: [country.downcase] } unless BLANK_LABELS.include?(country)
  end

  def recorder_search_query(recorder)
    { recorded_by_eq: recorder } unless BLANK_LABELS.include?(recorder)
  end

  # Search results page for a row, narrowing the report's current search (if any)
  def count_table_search_path(query)
    search_items_path(q: (@search_query || {}).with_indifferent_access.merge(query))
  end
end

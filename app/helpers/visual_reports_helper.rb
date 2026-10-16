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
    search_items_path(q: narrow_search_query(@search_query || {}, query))
  end

  # Combines the report's search with a row's query so the result matches both: date bounds keep the
  # narrower range and value lists keep their common values, instead of the row replacing the search's filter
  def narrow_search_query(search_query, row_query)
    search_query.with_indifferent_access.merge(row_query) do |key, search_value, row_value|
      next row_value if search_value.blank?

      case key.to_s
      when /_gteq\z/ then [search_value, row_value].max_by { |value| search_date(value) }
      when /_lteq\z/ then [search_value, row_value].min_by { |value| search_date(value) }
      when /_in\z/ then Array.wrap(search_value) & Array.wrap(row_value)
      else row_value
      end
    end
  end

  private

  # Date from a search bound; a bound that isn't a date sorts outside the row's range, so the row's bound is used
  def search_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    Date.new(-9999)
  end
end

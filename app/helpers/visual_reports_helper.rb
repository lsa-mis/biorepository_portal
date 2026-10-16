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
    { recorded_by_trimmed_eq: recorder } unless BLANK_LABELS.include?(recorder)
  end

  # Search results page for a row, narrowing the report's current search (if any), or nil when it can't be narrowed.
  # A search that combines its top-level filters with OR (q[m]=or) would need a nested group, which the search page
  # (form, sidebar and filter badges) can't represent, so its rows are not linked.
  def count_table_search_path(query)
    search_query = @search_query || {}
    return unless search_query.with_indifferent_access[:m].blank? || search_query.with_indifferent_access[:m] == "and"

    search_items_path(q: narrow_search_query(search_query, query))
  end

  # Combines the report's search with a row's query so the result matches both: date bounds keep the
  # narrower range and value lists keep their common values, instead of the row replacing the search's filter
  def narrow_search_query(search_query, row_query)
    search_query.with_indifferent_access.merge(row_query) do |key, search_value, row_value|
      next row_value if search_value.blank?

      case key.to_s
      when /_gteq\z/ then narrower_date_bound(search_value, row_value) { |search_date, row_date| search_date > row_date }
      when /_lteq\z/ then narrower_date_bound(search_value, row_value) { |search_date, row_date| search_date < row_date }
      when /_in\z/ then Array.wrap(search_value) & Array.wrap(row_value)
      else row_value
      end
    end
  end

  private

  # The search's date bound when it is narrower than the row's (the block compares them), otherwise the row's.
  # A search bound that isn't a date is ignored by the search (Ransack casts dates the same way), so the row's is used.
  def narrower_date_bound(search_value, row_value)
    search_date = ActiveModel::Type::Date.new.cast(search_value)
    row_date = ActiveModel::Type::Date.new.cast(row_value)
    search_date && yield(search_date, row_date) ? search_value : row_value
  end
end

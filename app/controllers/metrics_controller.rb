class MetricsController < ApplicationController
  include ActiveFiltersHelper
  include SearchGroupings
  skip_before_action :authenticate_user!

  # All reports on one page: the map, items by collection and items in all collections
  def index
    authorize :metric
    setup_search_summary
    load_mapped_items
    load_items_by_collection
    load_items_in_all_collections
  end

  # Map data for the items map on the index page.
  # One point per location, so the response grows with the number of collecting sites, not items.
  # Each point is [latitude, longitude, item count, id of an item at that location].
  def map_items
    authorize :metric
    locations = mappable_items.group(:decimal_latitude, :decimal_longitude)
                              .pluck(:decimal_latitude, :decimal_longitude, Arel.sql("COUNT(*)"), Arel.sql("MIN(items.id)"))
    render json: locations
  end

  private

  # Every collection is listed, with 0 when none of its items match the search
  def load_items_by_collection
    divisions = Collection.distinct.pluck(:division)
    @items_by_collection = divisions.index_with(0).merge(search_items.joins(:collection).group("collections.division").count)
    @collection_ids_by_division = Collection.group(:division).pluck(:division, Arel.sql("ARRAY_AGG(collections.id)")).to_h

    # Preparation types that differ only in case are one group (as the search does), labelled with the most common
    # spelling. Items without a preparation type share a group with a literal "No preparation" value.
    prep_type = "LOWER(NULLIF(preparations.prep_type, ''))"
    prep_group = "COALESCE(#{prep_type}, 'no preparation')"
    prep_label = "CASE WHEN #{prep_group} = 'no preparation' THEN 'No preparation' " \
                 "ELSE MODE() WITHIN GROUP (ORDER BY preparations.prep_type) END"
    preparation_counts = search_items.joins(:collection).left_joins(:preparations)
                                     .group("collections.division", Arel.sql(prep_group))
                                     .pluck("collections.division", Arel.sql(prep_label), Arel.sql("COUNT(DISTINCT items.id)"))
    counts_by_division = preparation_counts.each_with_object({}) do |(division, preparation_type, count), grouped|
      (grouped[division] ||= {})[preparation_type] = count if count.positive?
    end
    @preparation_counts_by_collection = Collection.order(:division).map do |collection|
      [collection, counts_by_division[collection.division] || {}]
    end
  end

  def load_items_in_all_collections
    collection_year = Arel.sql("EXTRACT(YEAR FROM items.event_date_start)::integer")
    @items_by_year = search_items.where.not(event_date_start: nil).group(collection_year).order(collection_year).count
    @items_by_country = counts_by_text_column(:country, case_insensitive: true).sort.to_h
    @items_by_recorder = counts_by_text_column(:recorded_by).sort_by { |name, count| [-count, name] }.to_h
  end

  def load_mapped_items
    @mapped_items = mappable_items.count
  end

  # Items with valid coordinates
  def mappable_items
    search_items.where(decimal_latitude: -90..90, decimal_longitude: -180..180)
  end

  # Items matching the advanced search query (same filtering as the CSV export), or all items.
  # Matching ids are selected in a subquery so search joins don't duplicate items in the report counts.
  def search_items
    @search_items ||= if params[:q].present?
      transform_search_groupings
      matching_ids = Item.left_outer_joins(:current_identification, :collection).ransack(params[:q]).result.select("items.id")
      Item.where(id: matching_ids)
    else
      Item.all
    end
  end

  # Search query, selected filters and item counts shown above a report, as on the search results page
  def setup_search_summary
    # Keep the untransformed search query for links back to the search and to the map data
    @search_query = params[:q].present? ? params[:q].to_unsafe_h : nil
    @total_items = search_items.count
    @collections = Collection.where(id: search_items.select(:collection_id)).order(:division).pluck(:division).join(", ")
    setup_dynamic_fields
    @active_filters = format_active_filters(dynamic_fields: @dynamic_fields)
  end

  # Item counts grouped by a text column; blank values are counted as "Not available".
  # case_insensitive groups values that differ only in case (as the search does), labelled with the most common spelling.
  def counts_by_text_column(column, case_insensitive: false)
    not_available = MetricsHelper::NOT_AVAILABLE
    value = "NULLIF(BTRIM(items.#{column}), '')"
    unless case_insensitive
      return search_items.group(Arel.sql("COALESCE(#{value}, #{Item.connection.quote(not_available)})")).count
    end

    # Blank values (no label) and a value spelled like "Not available" in any case are separate groups;
    # both get the "Not available" label and their counts are summed into one row
    search_items.group(Arel.sql("LOWER(#{value})"))
                .pluck(Arel.sql("MODE() WITHIN GROUP (ORDER BY #{value})"), Arel.sql("COUNT(*)"))
                .each_with_object(Hash.new(0)) do |(label, count), counts|
                  label = not_available if label.nil? || label.casecmp?(not_available)
                  counts[label] += count
                end
  end
end

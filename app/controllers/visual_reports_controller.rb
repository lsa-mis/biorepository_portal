class VisualReportsController < ApplicationController
  include ActiveFiltersHelper
  include SearchGroupings
  skip_before_action :authenticate_user!

  def index
    authorize :visual_report
  end

  def items_by_collection
    authorize :visual_report
    @items_by_collection = Collection.left_joins(:items).group(:division).count("items.id")
    @collection_ids_by_division = Collection.group(:division).pluck(:division, Arel.sql("ARRAY_AGG(collections.id)")).to_h

    preparation_counts = Collection.left_joins(items: :preparations)
                                   .group("collections.division", "COALESCE(NULLIF(preparations.prep_type, ''), 'No preparation')")
                                   .distinct
                                   .count("items.id")
    counts_by_division = preparation_counts.each_with_object({}) do |((division, preparation_type), count), grouped|
      (grouped[division] ||= {})[preparation_type] = count if count.positive?
    end
    @preparation_counts_by_collection = Collection.order(:division).map do |collection|
      [collection, counts_by_division[collection.division] || {}]
    end
  end

  def items_in_all_collections
    authorize :visual_report
    setup_search_summary
    collection_year = Arel.sql("EXTRACT(YEAR FROM items.event_date_start)::integer")
    @items_by_year = search_items.where.not(event_date_start: nil).group(collection_year).order(collection_year).count
    @items_by_country = counts_by_text_column(:country, case_insensitive: true).sort.to_h
    @items_by_recorder = counts_by_text_column(:recorded_by).sort_by { |name, count| [-count, name] }.to_h
  end

  def map_items
    authorize :visual_report
    respond_to do |format|
      format.html do
        setup_search_summary
        @mapped_items = search_items.where(decimal_latitude: -90..90, decimal_longitude: -180..180).count
      end
      format.json do
        # One point per location, so the response grows with the number of collecting sites, not items.
        # Each point is [latitude, longitude, item count, id of an item at that location].
        locations = search_items.where(decimal_latitude: -90..90, decimal_longitude: -180..180)
                                .group(:decimal_latitude, :decimal_longitude)
                                .pluck(:decimal_latitude, :decimal_longitude, Arel.sql("COUNT(*)"), Arel.sql("MIN(items.id)"))
        render json: locations
      end
    end
  end

  private

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

  # Item counts grouped by a text column; blank values are counted as "Unknown".
  # case_insensitive groups values that differ only in case (as the search does), labelled with the most common spelling.
  def counts_by_text_column(column, case_insensitive: false)
    value = "NULLIF(BTRIM(items.#{column}), '')"
    return search_items.group(Arel.sql("COALESCE(#{value}, 'Unknown')")).count unless case_insensitive

    # Blank values and a literal "Unknown" are separate groups with the same label, so their counts are summed
    search_items.group(Arel.sql("LOWER(#{value})"))
                .pluck(Arel.sql("COALESCE(MODE() WITHIN GROUP (ORDER BY #{value}), 'Unknown')"), Arel.sql("COUNT(*)"))
                .each_with_object(Hash.new(0)) { |(label, count), counts| counts[label] += count }
  end
end

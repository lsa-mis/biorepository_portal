class VisualReportsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    authorize :visual_report
  end

  def items_by_collection
    authorize :visual_report
    @items_by_collection = Collection.left_joins(:items).group(:division).count("items.id")

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
    collection_year = Arel.sql("EXTRACT(YEAR FROM items.event_date_start)::integer")
    @items_by_year = Item.where.not(event_date_start: nil).group(collection_year).order(collection_year).count
    country = Arel.sql("COALESCE(NULLIF(BTRIM(items.country), ''), 'Unknown')")
    @items_by_country = Item.group(country).order(country).count
    recorder = Arel.sql("COALESCE(NULLIF(BTRIM(items.recorded_by), ''), 'Unknown')")
    @items_by_recorder = Item.group(recorder).order(recorder).count
  end
end

class VisualReportsController < ApplicationController
  def index
  end

  def items_by_collection
    @items_by_collection = Collection.left_joins(:items).group(:division).count

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
    collection_year = Arel.sql("EXTRACT(YEAR FROM items.event_date_start)::integer")
    @items_by_year = Item.where.not(event_date_start: nil).group(collection_year).order(collection_year).count
    country = Arel.sql("COALESCE(NULLIF(BTRIM(items.country), ''), 'Unknown')")
    @items_by_country = Item.group(country).order(country).count
    recorder = Arel.sql("COALESCE(NULLIF(BTRIM(items.recorded_by), ''), 'Unknown')")
    recorder_counts = Item.group(recorder).count
    top_recorder_counts = recorder_counts.sort_by { |name, count| [-count, name] }.first(10).to_h
    other_count = recorder_counts.values.sum - top_recorder_counts.values.sum
    top_recorder_counts["Other recorded_by values"] = other_count if other_count.positive?
    @items_by_recorder = top_recorder_counts
  end
end

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
    @items_by_country = counts_by_text_column(:country).sort.to_h
    @items_by_recorder = counts_by_text_column(:recorded_by).sort_by { |name, count| [-count, name] }.to_h
  end

  def map_items
    authorize :visual_report
    respond_to do |format|
      format.html
      format.json do
        points = Item.joins(:collection)
                     .where(decimal_latitude: -90..90, decimal_longitude: -180..180)
                     .pluck(:id, :decimal_latitude, :decimal_longitude, :catalog_number, "collections.division")
        render json: points
      end
    end
  end

  private

  # Item counts grouped by a text column; blank values are counted as "Unknown"
  def counts_by_text_column(column)
    value = Arel.sql("COALESCE(NULLIF(BTRIM(items.#{column}), ''), 'Unknown')")
    Item.group(value).count
  end
end

require 'csv'
require 'set'

class ItemImportService
  attr_reader :file, :collection_id

  def initialize(file, collection_id)
    @file = file
    @collection_id = collection_id
    @items_in_db = Set.new(Item.where(collection_id: @collection_id).pluck(:occurrence_id))
    @field_names = {}
  end

  # This method is the main entry point for the CSV import process.
  # It reads the CSV file, processes each row, and updates or creates items in the database.
  def call
    Rails.logger.info("***** Processing Items File: #{@file.original_filename}")
    CSV.foreach(@file.path, headers: true) do |row|
      record = row.fields.map { |val| val&.delete('"')&.strip }

      next if record[0].blank?

      if item_exist?(record[0])
        update_item(record)
      else
        save_item(record)
      end
    end

    cleanup_removed_items

  end

  private

  def item_exist?(occurrence_id)
    @items_in_db.include?(occurrence_id)
  end

  def save_item(record)
    item = Item.new(collection_id: @collection_id)
    preparations_string = assign_fields(item, record)
    if item.save
      update_preparations(item, preparations_string)
    else
      Rails.logger.error("Failed to save item: #{item.errors.full_messages.join(', ')}")
    end
  rescue => e
    Rails.logger.error("Error saving item: #{e.message}")
  end

  def update_item(record)
    item = Item.find_by(occurrence_id: record[0])
    return unless item

    preparations_string = assign_fields(item, record)

    if item.save
      @items_in_db.delete(item.occurrence_id)
      update_preparations(item, preparations_string)
    else
      Rails.logger.error("Failed to update item: #{item.errors.full_messages.join(', ')}")
    end
  rescue => e
    Rails.logger.error("Error updating item: #{e.message}")
  end

  def assign_fields(item, record)
    preparations_string = nil

    @field_names = build_field_names if @field_names.empty?
    @field_names.each_with_index do |(field, table), index|
      next if field.include?("ignore")

      value = record[index]&.strip
      next unless value.present?

      case table
      when "items"
        case field
        when "event_date"
          handle_event_date(item, value)
        when "modified", "georeferenced_date"
          item.assign_attributes(field => parse_date(value))
        when "individual_count"
          item.assign_attributes(field => value.to_i)
        when "minimum_elevation_in_meters", "maximum_elevation_in_meters",
            "decimal_latitude", "decimal_longitude", "coordinate_uncertainty_in_meters"
          item.assign_attributes(field => value.to_f)
        else
          item.assign_attributes(field => value)
        end
      when "preparations"
        preparations_string = value
      else
        Rails.logger.debug("Skipping field from unknown table: #{table}")
      end
    end

    preparations_string
  end

  def parse_date(value)
    Date.parse(value) rescue nil
  end

  def build_field_names
    header = CSV.open(@file.path, &:readline)
    header.each_with_object({}) do |h, hash|
      map_field = MapField.find_by(specify_field: h.strip)
      hash[map_field.rails_field] = map_field.table if map_field
    end
  end

  def handle_event_date(item, value)
    if value.include?('/')
      start_str, end_str = value.split('/', 2).map(&:strip)
      item.event_date_start = Date.parse(start_str)
      item.event_date_end   = Date.parse(end_str)
    else
      date = Date.parse(value.strip)
      item.event_date_start = date
      item.event_date_end   = date
    end
  rescue ArgumentError => e
    Rails.logger.error("Invalid eventDate format: '#{value}' — #{e.message}")
  end


  def update_preparations(item, preparations_string)
    if preparations_string.blank?
      item.destroy
      return true
    end

    # Remove all existing preparations for the item
    item.preparations.destroy_all

    prep_entries = preparations_string.split(';').map(&:strip)

    prep_entries.each do |entry|
      values = entry.split(':')
      prep_type, count = extract_prep_type_and_count(values)

      next if prep_type.blank?

      preparation = Preparation.new(item: item, prep_type: prep_type, count: count)

      update_prep_fields(preparation, values)
      unless preparation.save
        Rails.logger.error("Failed to save preparation (#{prep_type}): #{preparation.errors.full_messages.join(', ')}")
        return false
      end
    end

    true
  rescue => e
    Rails.logger.error("Error updating preparations: #{e.message}")
    false
  end


  def extract_prep_type_and_count(values)
    parts = values[0].to_s.split('-').map(&:strip)
    prep_type = parts[0]

    # FIXME: Default Count to 0?
    count = parts[1].to_i if parts[1]
    [prep_type, count || 0]
  end

  def update_prep_fields(preparation, values)
    preparation.barcode = values[1]&.strip
    preparation.description = values[2]&.strip
  end

  def cleanup_removed_items
    @items_in_db.each do |occurrence_id|
      item = Item.find_by(occurrence_id: occurrence_id)
      item&.destroy
    end
  end
end

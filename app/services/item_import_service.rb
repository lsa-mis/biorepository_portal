require 'set'

class ItemImportService
  attr_reader :file, :collection_id

  DATE_FIELDS = %w[modified georeferenced_date].freeze
  INTEGER_FIELDS = %w[individual_count].freeze
  FLOAT_FIELDS = %w[minimum_elevation_in_meters maximum_elevation_in_meters
                    decimal_latitude decimal_longitude coordinate_uncertainty_in_meters].freeze
  # Four-digit-year formats are tried before two-digit ones; see parse_flexible_date
  DATE_FORMATS = [
    '%Y-%m-%d', '%m/%d/%Y', '%m-%d-%Y', '%Y-%m', '%Y',
    '%m/%d/%y', '%m-%d-%y', '%d/%m/%y', '%d-%m-%y'
  ].freeze

  def initialize(file, collection_id, user)
    @file = file
    @collection_id = collection_id
    @user = user
    @collection = Collection.find(@collection_id)
    @items_by_occurrence = Item.where(collection_id: @collection_id).index_by(&:occurrence_id)
    # Occurrence ids still in this set after the import are not in the file and get removed
    @items_not_in_file = @items_by_occurrence.keys.to_set
    @columns = nil
    @log = ImportLog.new
    @notes = []
    @errors = 0
    @result = { errors: 0, note: [], time: 0 }
  end

  # This method is the main entry point for the CSV import process.
  # It reads the CSV file, processes each row, and updates or creates items in the database.
  def call
    total_time = Benchmark.measure {
      @log.import_logger.info("#{DateTime.now} - #{@collection.division} - Processing Occurrence File: #{@file.original_filename}")
      CSV.foreach(@file.path, headers: true, encoding: 'bom|utf-8') do |row|
        record = row.fields.map { |val| val&.delete('"')&.strip }
        occurrence_id = record[0]
        next if occurrence_id.blank?

        # Mark the item as present before saving, so a failed update does not delete it
        @items_not_in_file.delete(occurrence_id)
        item = @items_by_occurrence[occurrence_id] || Item.new(collection: @collection)
        import_item(item, record)
      end
      cleanup_removed_items
    }
    task_time = (total_time.real / 60).round(2)
    @log.import_logger.info("**** ItemImportService, Occurrence import completed. Total time: #{task_time} minutes.")
    @notes << "Occurrence import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @notes.reverse # Reverse to maintain order of processing
    @result[:time] = task_time
    return @result
    rescue => e
      @log.import_logger.error("**** ItemImportService, Error importing Item: #{e.message}")
      @notes << "Occurrence import: Error importing Item. Error: #{e.message}"
      @result[:errors] = @errors + 1
      @result[:note] = @notes.reverse
      return @result
  end

  private

  def import_item(item, record)
    action = item.new_record? ? "save" : "update"
    preparations_string = assign_fields(item, record)

    # Items without preparations are not kept in the portal
    if preparations_string.blank?
      if item.persisted?
        item.destroy
        @items_by_occurrence.delete(item.occurrence_id)
      end
      return
    end

    if item.save
      # A later row with the same occurrence id updates this item instead of failing uniqueness
      @items_by_occurrence[item.occurrence_id] = item
      update_preparations(item, preparations_string)
    else
      add_error("Failed to #{action} item", item, item.errors.full_messages.join(', '))
    end
  rescue => e
    add_error("Error #{action == 'save' ? 'saving' : 'updating'} item", item, e.message)
  end

  def assign_fields(item, record)
    preparations_string = nil

    columns.each do |index, field, table|
      value = record[index].presence

      case table
      when "items"
        case field
        when "event_date"
          handle_event_date(item, value)
        when *DATE_FIELDS
          item.assign_attributes(field => parse_date(value))
        when *INTEGER_FIELDS
          item.assign_attributes(field => value&.to_i)
        when *FLOAT_FIELDS
          item.assign_attributes(field => value&.to_f)
        else
          item.assign_attributes(field => value)
        end
      when "preparations"
        preparations_string = value
      end
    end

    preparations_string
  end

  def parse_date(value)
    Date.parse(value) rescue nil
  end

  # Returns [csv_column_index, rails_field, table] for every mapped, non-ignored header.
  # The index is the column's position in the file, so unmapped headers do not shift values.
  def columns
    @columns ||= begin
      header = CSV.open(@file.path, encoding: 'bom|utf-8', &:readline).map { |h| h.to_s.strip }
      map_fields_by_specify_field = MapField.where(specify_field: header, table: ["items", "preparations"]).index_by(&:specify_field)

      header.each_with_index.filter_map do |h, index|
        map_field = map_fields_by_specify_field[h]
        next if map_field.nil? || map_field.rails_field.include?("ignore")

        [index, map_field.rails_field, map_field.table]
      end
    end
  end

  def update_preparations(item, preparations_string)
    # Remove all existing preparations for the item
    Preparation.where(item_id: item.id).delete_all

    prep_entries = preparations_string.split(';').map(&:strip)

    prep_entries.each do |entry|
      values = entry.split(':')
      prep_type, count = extract_prep_type_and_count(values)

      next if prep_type.blank?

      preparation = Preparation.new(item: item, prep_type: prep_type, count: count)

      update_prep_fields(preparation, values)
      unless preparation.save
        add_error("Failed to save preparation (#{prep_type})", item, preparation.errors.full_messages.join(', '))
      end
    end
  rescue => e
    add_error("Error updating preparations", item, e.message)
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
    return if @items_not_in_file.empty?

    Item
      .where(collection_id: @collection_id, occurrence_id: @items_not_in_file.to_a)
      .includes(:identifications, :preparations)
      .find_each(&:destroy)
  end

  # eventDate is either a single date or an ISO 8601 range ("2024-09-16/2024-09-20").
  # A value such as "9/16/24" also contains "/", so it is parsed as a single date first.
  def handle_event_date(item, value)
    if value.blank?
      item.event_date_start = nil
      item.event_date_end = nil
      return
    end

    if (date = parse_flexible_date(value))
      item.event_date_start = date
      item.event_date_end = nil
      return
    end

    start_str, end_str = value.split('/', 2).map(&:strip)
    start_date = parse_flexible_date(start_str)
    end_date = parse_flexible_date(end_str)
    if start_date && end_date
      item.event_date_start = start_date
      item.event_date_end = end_date
    else
      add_error("Invalid eventDate format", item, "'#{value}'")
    end
  end

  def parse_flexible_date(string)
    return nil if string.blank?

    # Drop a time part, e.g. "2024-09-16T10:30" or "2024-09-16 10:30"
    string = string.sub(/[T ]\d{1,2}:\d{2}.*\z/, '')
    DATE_FORMATS.each do |fmt|
      date = Date.strptime(string, fmt) rescue next
      # strptime ignores trailing text and accepts a short %Y, so "9/16/24" would become
      # year 24 with '%m/%d/%Y'; only accept a parse that round-trips to the same value
      next unless date.strftime(fmt) == normalize_date_string(string, fmt)

      # Two-digit years 00-68 parse as 2000-2068; a collection date cannot be in the future
      return fmt.include?('%y') && date > Date.current ? date.prev_year(100) : date
    end
    # Fallback for written-out dates such as "16 September 2024"
    Date.parse(string) if string.match?(/[a-z]/i)
  rescue ArgumentError
    nil
  end

  # Pads month/day so "9/6/2024" compares equal to strftime's "09/06/2024"
  def normalize_date_string(string, fmt)
    separator = fmt[/[\/-]/]
    return string unless separator

    string.split(separator).map { |part| part.length == 1 ? "0#{part}" : part }.join(separator)
  end

  def add_error(message, item, detail)
    @log.import_logger.error("**** ItemImportService, #{message}. Item: #{item&.occurrence_id}. Error: #{detail}")
    @errors += 1
    @notes << "Occurrence import: #{message}. Item: #{item&.occurrence_id}. Error: #{detail}"
  end
end

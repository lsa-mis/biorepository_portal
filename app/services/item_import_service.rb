require 'csv'
require 'set'

class ItemImportService
  attr_reader :file, :collection_id

  def initialize(file, collection_id, user)
    @file = file
    @collection_id = collection_id
    @user = user
    @items_in_db = Set.new(Item.where(collection_id: @collection_id).pluck(:occurrence_id))
    @field_names = {}
    @log = ImportLog.new
    @notes = []
    @errors = 0
    @result = { errors: 0, note: [] }
  end

  # This method is the main entry point for the CSV import process.
  # It reads the CSV file, processes each row, and updates or creates items in the database.
  def call
    total_time = Benchmark.measure {
      @log.import_logger.info("#{DateTime.now} - #{Collection.find(@collection_id).division} - Processing Occurrence File: #{@file.original_filename}")
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
    }
    task_time = ((total_time.real / 60) % 60).round(2)
    @log.import_logger.info("***********************Occurrence import completed. Total time: #{task_time} minutes.")
    @notes << "Occurrence import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @notes.reverse # Reverse to maintain order of processing
    return @result
    rescue => e
      @log.import_logger.error("***********************Error importing Item: #{e.message}")
      @notes << "Occurrence import: Error importing Item. File: #{@file.original_filename}. Error: #{e.message}"
      @result[:errors] = @errors + 1
      @result[:note] = @notes.reverse
      return @result
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
      @log.import_logger.error("***********************Failed to save item: #{item.errors.full_messages.join(', ')}")
      @errors += 1
      @notes << "Occurrence import: Failed to save item. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{item.errors.full_messages.join(', ')}"
    end
  rescue => e
    @log.import_logger.error("***********************Error saving item: #{e.message}")
    @errors += 1
    @notes << "Occurrence import: Error saving item. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{e.message}"
  end

  def update_item(record)
    item = Item.find_by(occurrence_id: record[0])
    return unless item

    preparations_string = assign_fields(item, record)

    if item.save
      @items_in_db.delete(item.occurrence_id)
  
      update_preparations(item, preparations_string)
    else
      @log.import_logger.error("***********************Failed to update item: #{item.errors.full_messages.join(', ')}")
      @errors += 1
      @notes << "Occurrence import: failed to update item. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{item.errors.full_messages.join(', ')}"
    end
  rescue => e
    @log.import_logger.error("***********************Error updating item: #{e.message}")
    @errors += 1
    @notes << "Occurrence import: Error updating item. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{e.message}"
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
        # @log.import_logger.error("***********************Item - skipping field from: #{table}")
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

  def update_preparations(item, preparations_string)
    if preparations_string.blank?
      item.destroy
      # add log entry for item deletion
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
        @log.import_logger.error("***********************Failed to save preparation (#{prep_type}): #{preparation.errors.full_messages.join(', ')}")
        @errors += 1
        @notes << "Occurrence import: Failed to save preparation (#{prep_type}). File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{preparation.errors.full_messages.join(', ')}"
      end
    end
  rescue => e
    @log.import_logger.error("***********************Error updating preparations: #{e.message}")
    @errors += 1
    @notes << "Occurrence import: Error updating preparations. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{e.message}"
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

  def is_date?(string)
    return true if string.to_date
    rescue ArgumentError
      false
  end

  def handle_event_date(item, value)
    date = parse_flexible_date(value)
    if date
      item.event_date_start = date
    else
      @log.import_logger.error("***********************#{item.occurrence_id} - Invalid eventDate format: '#{value}' — #{e.message}")
      @errors += 1
      @notes << "Occurrence import: Invalid eventDate format. File: #{@file.original_filename}, Item: #{item.occurrence_id}. Error: #{e.message}"
      item.verbatim_event_date = value.strip
    end
  rescue ArgumentError => e
    @log.import_logger.error("***********************#{item.occurrence_id} - Invalid eventDate format: '#{value}' — #{e.message}")
    @errors += 1
    @notes << "Occurrence import: Invalid eventDate format. File: #{@file.original_filename}, Item: #{item.occurrence_id}. Error: #{e.message}"
  end

  # def handle_event_date(item, value)
  #   if is_date?(value)
  #     if value.include?('/')
  #       start_str, end_str = value.split('/', 2).map(&:strip)
  #       item.event_date_start = Date.parse(start_str)
  #       item.event_date_end   = Date.parse(end_str)
  #     else
  #       date = Date.parse(value.strip)
  #       item.event_date_start = date
  #       item.event_date_end   = date
  #     end
  #   else
  #     @log.import_logger.error("***********************#{item.occurrence_id} - Invalid eventDate format: '#{value}' — #{e.message}")
  #     item.verbatim_event_date = value.strip
  #   end
  # # rescue ArgumentError => e
  # #   @log.import_logger.error("***********************#{item.occurrence_id} - Invalid eventDate format: '#{value}' — #{e.message}")
  # end

  def parse_flexible_date(string)
    return nil if string.blank?
    formats = [
      '%m/%d/%Y', '%-m/%-d/%Y', '%Y', '%d-%m-%Y', '%-d-%-m-%Y', '%m/%d/%y', '%-m/%-d/%y', '%d-%m-%y', '%-d-%-m-%y', '%Y-%m-%d'
    ]
    formats.each do |fmt|
      begin
        return Date.strptime(string, fmt)
      rescue ArgumentError
        next
      end
    end
    # Fallback to Date.parse for other valid formats
    begin
      return Date.parse(string)
    rescue ArgumentError
      false
    end
  end
end

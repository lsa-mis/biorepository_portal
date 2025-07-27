require 'csv'
require 'set'

class IdentificationImportService
  attr_reader :file

  def initialize(file, collection_id, user)
    @file = file
    @collection_id = collection_id
    @user = user
    @field_names = {}
    @log = ImportLog.new
    @note = []
    @errors = 0
    @result = { errors: 0, note: "" }
  end

  # Assumes:
  # - First column is occurrence_id (linked to Item)
  def call
    @errors = 0
    total_time = Benchmark.measure {
      @log.import_logger.info("#{DateTime.now} - #{Collection.find(@collection_id).division} - Processing Identifications File: #{@file.original_filename}")
      # Group rows by occurrence_id
      grouped_rows = Hash.new { |h, k| h[k] = [] }

      CSV.foreach(@file.path, headers: true) do |row|
        occurrence_id = row.fields[0]&.delete('"')&.strip
        next if occurrence_id.blank?

        grouped_rows[occurrence_id] << row.drop(1)
      end
      grouped_rows.each do |occurrence_id, rows|
        item = Item.find_by(occurrence_id: occurrence_id)
        next unless item

        # Remove existing identifications for this item
        item.identifications.destroy_all

        rows.each do |row|
          save_identification(item, row)
        end
      end
    }
    task_time = ((total_time.real / 60) % 60).round(2)
    @log.import_logger.info("***********************Identification import completed. Total time: #{task_time} minutes.")
    @note << "Identification import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @note
    return @result
    
  rescue => e
    @log.import_logger.error("***********************Error importing identifications: #{e.message}")
    @note << "Identification import: Error importing identifications. File: #{@file.original_filename}. Error: #{e.message}"
    @result[:errors] = @errors + 1
    @result[:note] = @note
    return @result
  end

  private

  def save_identification(item, row)
    identification = Identification.new(item_id: item.id)

    assign_fields(identification, row)

    unless identification.save
      @log.import_logger.error("***********************Failed to save identification: #{identification.errors.full_messages.join(', ')}")
      @errors += 1
      @note << "Identification import: Failed to save identification. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{identification.errors.full_messages.join(', ')}"
    end
  rescue => e
    @log.import_logger.error("***********************Error saving identification: #{e.message}")
    @errors += 1
    @note << "Identification import: Error saving identification. File: #{@file.original_filename}. Item: #{item.occurrence_id}. Error: #{e.message}"
  end

  def assign_fields(identification, row)
    @field_names = build_field_names if @field_names.empty?
    row_hash = Hash[*row.flatten]
    @field_names.each_with_index do |(field, _table), index|
      next unless _table == "identifications"
      next if field.include?("ignore")
      field_in_row = MapField.find_by(rails_field: field, table: _table).specify_field
      value = row_hash[field_in_row]&.strip
      next if value.blank?

      if field == "current"
        identification.current = handle_current(value)
      else
        identification.assign_attributes(field => value)
      end
    end
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

  def handle_current(value)
    case value.downcase
    when "true", "1", "yes" then true
    when "false", "0", "no" then false
    else nil
    end
  rescue
    nil
  end
end

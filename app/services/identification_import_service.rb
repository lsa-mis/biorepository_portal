require 'set'

class IdentificationImportService
  attr_reader :file

  def initialize(file, collection_id, user)
    @file = file
    @collection_id = collection_id
    @user = user
    @columns = nil
    @log = ImportLog.new
    @notes = []
    @errors = 0
    @result = { errors: 0, note: [], time: 0 }
  end

  # Assumes:
  # - First column is occurrence_id (linked to Item)
  def call
    @errors = 0
    total_time = Benchmark.measure {
      @log.import_logger.info("#{DateTime.now} - #{Collection.find(@collection_id).division} - Processing Identifications File: #{@file.original_filename}")
      # Group rows by occurrence_id
      grouped_rows = Hash.new { |h, k| h[k] = [] }

      CSV.foreach(@file.path, headers: true, encoding: 'bom|utf-8') do |row|
        occurrence_id = row.fields[0]&.delete('"')&.strip
        next if occurrence_id.blank?

        grouped_rows[occurrence_id] << row.drop(1)
      end
      items_by_occurrence = Item.where(collection_id: @collection_id, occurrence_id: grouped_rows.keys).index_by(&:occurrence_id)

      missing = grouped_rows.keys - items_by_occurrence.keys
      @log.import_logger.info("**** IdentificationImportService, #{missing.size} occurrence id(s) not found in the collection: #{missing.first(20).join(', ')}") if missing.any?

      grouped_rows.each do |occurrence_id, rows|
        item = items_by_occurrence[occurrence_id]
        next unless item

        replace_identifications(item, rows)
      end
    }
    task_time = (total_time.real / 60).round(2)
    @log.import_logger.info("**** IdentificationImportService, Identification import completed. Total time: #{task_time} minutes.")
    @notes << "Identification import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @notes.reverse # Reverse to maintain order of processing
    @result[:time] = task_time
    return @result
    
  rescue => e
    @log.import_logger.error("**** IdentificationImportService, Error importing identifications: #{e.message}")
    @notes << "Identification import: Error importing identifications. Error: #{e.message}"
    @result[:errors] = @errors + 1
    @result[:note] = @notes.reverse
    return @result
  end

  private

  # Replaces the item's identifications with the rows from the file. If any row fails,
  # the item keeps its existing identifications.
  def replace_identifications(item, rows)
    Identification.transaction do
      Identification.where(item_id: item.id).delete_all
      identifications = rows.map { |row| item.identifications.build.tap { |identification| assign_fields(identification, row) } }
      invalid = identifications.reject(&:save)
      next if invalid.empty?

      invalid.each { |identification| add_error("Failed to save identification", item, identification.errors.full_messages.join(', ')) }
      raise ActiveRecord::Rollback
    end
  rescue => e
    add_error("Error saving identification", item, e.message)
  end

  def assign_fields(identification, row)
    row_hash = Hash[*row.flatten]
    columns.each do |header, field|
      value = row_hash[header]&.strip
      next if value.blank?

      if field == "current"
        current = handle_current(value)
        identification.current = current unless current.nil?
      else
        identification.assign_attributes(field => value)
      end
    end
  end

  # Returns [header, rails_field] for every mapped, non-ignored identification header
  def columns
    @columns ||= begin
      header = CSV.open(@file.path, encoding: 'bom|utf-8', &:readline)
      map_fields_by_specify_field = MapField.where(specify_field: header.map { |h| h.to_s.strip }, table: ["identifications"]).index_by(&:specify_field)

      header.filter_map do |h|
        map_field = map_fields_by_specify_field[h.to_s.strip]
        next if map_field.nil? || map_field.rails_field.include?("ignore")

        [h, map_field.rails_field]
      end
    end
  end

  def handle_current(value)
    case value.downcase
    when "true", "1", "yes" then true
    when "false", "0", "no" then false
    end
  end

  def add_error(message, item, detail)
    @log.import_logger.error("**** IdentificationImportService, #{message}. Item: #{item.occurrence_id}. Error: #{detail}")
    @errors += 1
    @notes << "Identification import: #{message}. Item: #{item.occurrence_id}. Error: #{detail}"
  end
end

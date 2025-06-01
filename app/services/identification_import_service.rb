require 'csv'
require 'set'

class IdentificationImportService
  attr_reader :file

  def initialize(file)
    @file = file
    @field_names = {}
  end

  # Assumes:
  # - First column is occurrence_id (linked to Item)
  def call
    Rails.logger.info("***** Processing Identifications File: #{@file.original_filename}")
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

    Rails.logger.info("Identification import completed.")
  # rescue => e
  #   Rails.logger.error("Error importing identifications: #{e.message}")
  end

  private

  def save_identification(item, row)
    identification = Identification.new(item_id: item.id)

    assign_fields(identification, row)

    if identification.save
      Rails.logger.info("Saved identification for item #{item.occurrence_id}")
    else
      Rails.logger.error("Failed to save identification: #{identification.errors.full_messages.join(', ')}")
    end
  # rescue => e
  #   Rails.logger.error("Error saving identification: #{e.message}")
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

      case field
      when "current"
        identification.current = handle_current(value)
      # when "taxon_rank"
      #   identification.taxon_rank = value.to_i
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

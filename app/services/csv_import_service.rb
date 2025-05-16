class CsvImportService
  # require 'csv'

  def call(file, collection_id)
    @collection_id = collection_id
    File.open(file) do |f|
      header = f.readline.strip.split(",")
      @items_in_db = Item.pluck(:occurrence_id)
      @field_names = {}
      header.map { |h| @field_names[ MapField.find_by(specify_field: h.strip).rails_field ] = MapField.find_by(specify_field: h.strip).table }
      f.each_line.with_index do |line, index|
        s_cleaned = line.gsub(/"(.*?)"/) { |match| match.gsub(",", "") }
        record = s_cleaned.split(",")
        if record[0].blank?
          next
        end
        # check if record exists in database
        # item = Item.find_by(occurrence_id: record[0]&.strip)
        if item_exist?(record[0]&.strip)
          update_item(record)
        else
          save_item(record)
        end
      end
    end
    # check if items table has data that is not in Specify any more
    if @items_in_db.present?
      @items_in_db.each do |occurrence_id|
        item = Item.find_by(occurrence_id: occurrence_id)
        # check
        item.destroy if item.present?
      end
    end
  end

  def item_exist?(occurrence_id)
    @items_in_db.include?(occurrence_id)
  end

  def save_item(record)
    @item = Item.new
    @item.collection_id = @collection_id
    @field_names.each_with_index do |(field, table), index|
      if field.include?('ignore')
        next
      end
      # check the table in MapField
      value = record[index]&.delete('"').strip
      case table
      when "items"
        if value.present?
          if field == "event_date"
            handle_event_date(value)
          else
            # Assign the value to the item object
            @item.assign_attributes(field => value)
          end
        end
      when "preparations"
        if value.present?
          @preparations_string = value
        end
      else
        puts "saving item - ignore field for table: #{table}"
        next
      end
    end
    # Save the item and handle errors
    if @item.save
      unless create_preparations(@item, @preparations_string)
        puts "Failed to save preparation: #{@preparation.errors.full_messages.join(', ')}"
      end
    else
      puts "Failed to save item: #{@item.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    puts "Error saving item: #{e.message}"
  end
  
  def update_item(record)
    @item = Item.find_by(occurrence_id: record[0]&.strip)
    @field_names.each_with_index do |(field, table), index|
      if field == "occurrence_id"
        next
      end
      if field.include?('ignore')
        next
      end
      value = record[index]&.delete('"').strip
      case table
      when "items"
        if value.present?
          if field == "event_date"
            handle_event_date(value)
          else
            # Assign the value to the item object
            @item.assign_attributes(field => value)
          end
        end
      when "preparations"
        if value.present?
          @preparations_string = value
        end
      else
        puts "updating item - ignore fields for table: #{table}"
        next
      end
    end
    if @item.save
      @items_in_db.delete(@item.occurrence_id)
      unless update_preparations(@item, @preparations_string)
        puts "Failed to update preparations for item: #{@item.occurrence_id}"
      end
    else
      puts "Failed to save item: #{@item.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    puts "Error updating item: #{e.message}"
  end
  
  def create_preparations(item, preparations_string)
    preparations = preparations_string.split(';')
    preparations.each do |prep|
      preparation = Preparation.new
      values = prep.split(":")
      values_first = values[0].split('-')
      preparation.prep_type = values_first[0]&.strip
      preparation.count = values_first[1].to_i
      preparation.barcode = values[1]&.strip
      preparation.description = values[2]&.strip
      preparation.item = item
      unless preparation.save
        puts "Failed to save preparation: #{preparation.errors.full_messages.join(', ')}"
        return false
      end
    end
    return true
  rescue StandardError => e
    puts "Error creating preparation: #{e.message}"
    return false
  end
  
  def update_preparations(item, preparations_string)
    preparations = preparations_string.split(';')
    preparations.each do |prep|
      values = prep.split(":")
      values_first = values[0].split('-')
      preparation = Preparation.find_by(item: item, prep_type: values_first[0]&.strip)
      if preparation.present?
        preparation.count = values_first[1].to_i
        preparation.barcode = values[1]&.strip
        preparation.description = values[2]&.strip
        preparation.item = item
        unless preparation.save
          puts "Failed to update preparation: #{preparation.errors.full_messages.join(', ')}"
          return false
        end
      else
        unless create_preparations(item, prep)
          puts "Failed to create preparation: #{preparation.errors.full_messages.join(', ')}"
          return false
        end
      end
    end
    return true
  rescue StandardError => e
    puts "Error updating preparation: #{e.message}"
    return false
  end
  
  def handle_event_date(value)
    if value.include? '/'
      event_date_start = value.split("-")[0]
      event_date_end = value.split("-")[1]
    else
      event_date_start = value.strip.to_date
      event_date_end = value.strip.to_date
    end
    @item.event_date_start = event_date_start
    @item.event_date_end = event_date_end
  end
end

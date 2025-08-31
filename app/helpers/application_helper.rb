module ApplicationHelper

  def css_class_for_flash(type)
    case type.to_sym
    when :alert
      "alert-danger"
    else
      "alert-success"
    end
  end

  def user_role
    if is_developer?
      " - developer"
    elsif is_super_admin?
      " - super admin"
    elsif is_admin?
      " - admin"
    else
      ""
    end
  end

  def is_developer?
    session[:role] == "developer"
  end

  def is_super_admin?
    session[:role] == "super_admin" || session[:role] == "developer"
  end

  def is_admin?
    session[:role] == "admin" || session[:role] == "super_admin" || session[:role] == "developer"
  end

  def is_user?
    session[:role] == "user" || session[:role] == "admin" || session[:role] == "super_admin" || session[:role] == "developer"
  end

  def is_collection_admin?(collection)
    return false unless is_admin?
    return false unless session[:collection_ids].present?
    return false unless collection.present?
    return false unless collection.admin_group.present?
    return false unless session[:collection_ids].include?(collection.id)
    true
  end
  
  def get_uniqname(email)
    email.split("@").first
  end

  def show_current(identification)
    if identification.current
      "Current Identification:"
    else
      ""
    end
  end

  def render_flash_stream
    turbo_stream.update "flash", partial: "layouts/flash"
  end

  def pref_types
    AppPreference.pref_types.keys.map{ |key| [key.titleize, key] }
  end

  def string_to_boolean(value)
    return true if value == "1"
    return false if value == "0"
  end
  
  def show_boolean(value)
    value ? "Yes" : "No" 
  end
  
  def show_state_province_county(item)
    string = ""
    if item.state_province.present?
      string = item.state_province
    end
    if item.county.present?
      string += ", " + item.county
    end
    string
  end

  def preparation_checkout_counts(preparation, checkout)
    in_checkout = checkout.requestables.find_by(preparation_id: preparation.id)&.count.to_i
    available = preparation.count
    [in_checkout, available]
  end

  def item_views
    [
      [ 'Rows', 'rows' ],
      [ 'Cards', 'cards' ]
    ]
  end

  ITEM_FIELDS = Item.column_names.select { |name| !%w[id created_at updated_at collection_id].include?(name) }

  PREPARATIONS_FIELDS = Preparation.column_names.select { |name| !%w[id item_id created_at updated_at barcode count].include?(name) }
  IDENTIFICATIONS_FIELDS = Identification.column_names.select { |name| !%w[id item_id created_at updated_at].include?(name) }
  # Combine all fields into a single array for CSV headers
  HEADERS = ITEM_FIELDS + IDENTIFICATIONS_FIELDS + PREPARATIONS_FIELDS
  TITLEIZED_HEADERS = HEADERS.map { |h|
    case h
    when 'class_name' then 'Class'
    when 'order_name' then 'Order'
    else h.to_s.titleize
    end
  }

  def sanitize_csv_value(value)
    value.to_s.start_with?('=', '+', '-', '@') ? "'#{value}'" : value.to_s
  end

  def show_user_name_by_id(id)
    user = User.find_by(id: id)
    user ? user.name_with_email : "User not found"
  end

  def safe_return_path(return_to_param, fallback_path)
    return fallback_path if return_to_param.blank?
    
    begin
      uri = URI.parse(return_to_param)
      
      # Only allow relative URLs (no host/scheme) or same-host URLs
      if uri.relative? || (uri.host == request.host && uri.scheme.in?(['http', 'https']))
        return_to_param
      else
        fallback_path
      end
    rescue URI::InvalidURIError
      fallback_path
    end
  end

  def get_checkout_items
    checkout_items = []
    collection_ids = []
    @checkout.requestables.active.each do |requestable|
      preparation = requestable.preparation
      item = preparation.item
      checkout_item = ""
      checkout_item += "#{item.collection.division}, Catalog Number: #{item.catalog_number}, Scientific Name: #{item.current_identification&.scientific_name&.humanize}, Preparation: #{preparation.prep_type}"
      if preparation.barcode.present?
        checkout_item += ", Barcode: #{preparation.barcode}"
      end
      if preparation.description.present?
        checkout_item += ", Description: #{preparation.description}"
      end
      checkout_item += ", Count: #{requestable.count}"
      checkout_items << checkout_item
      collection_ids << item.collection_id    
    end
    [checkout_items, collection_ids.uniq]
  end

  def get_checkout_items_with_ids
    checkout_items = []
    @checkout.requestables.active.each do |requestable|
      preparation = requestable.preparation
      item = preparation.item
      checkout_item = ""
      checkout_item += "#{item.collection.division}, Catalog Number: #{item.catalog_number}, Scientific Name: #{item.current_identification&.scientific_name&.humanize}, Preparation: #{preparation.prep_type}"
      if preparation.barcode.present?
        checkout_item += ", Barcode: #{preparation.barcode}"
      end
      if preparation.description.present?
        checkout_item += ", Description: #{preparation.description}"
      end
      checkout_item += ", Count: #{requestable.count}"
      checkout_item += ", #{item.id}"
      checkout_items << checkout_item
    end
    checkout_items
  end
  
  def number_of_items_to_loan
    number = Rails.cache.fetch("number_of_items_to_loan", expires_in: 10.hours) do
      Item.count
    end
    number_with_delimiter(number)
  end

end

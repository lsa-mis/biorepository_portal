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
      "Current"
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
    available = [preparation.count - in_checkout, 0].max
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
    User.find(id).name_with_email
  end

end

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

  def show_count(preparation, max_number_of_preparations)
    max_number_of_preparations > 0 ? [preparation.count, max_number_of_preparations].min : preparation.count
  end

  def fetch_max_number_of_preparations(collection_id)
    AppPreference.find_by(name: "max_number_of_preparations", collection_id: collection_id)&.value.to_i || 0
  end

  def collection_max_preparations(collection_id)
    fetch_max_number_of_preparations(collection_id)
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

  def preparation_checkout_counts(preparation, checkout, max_number_of_preparations = nil)
    if max_number_of_preparations.nil?
      max_number_of_preparations = fetch_max_number_of_preparations(preparation.item.collection.id)
    end
    in_checkout = checkout.requestables.find_by(preparation_id: preparation.id)&.count.to_i
    available = [show_count(preparation, max_number_of_preparations) - in_checkout, 0].max
    [in_checkout, available]
  end

end

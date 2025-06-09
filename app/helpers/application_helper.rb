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
  
end

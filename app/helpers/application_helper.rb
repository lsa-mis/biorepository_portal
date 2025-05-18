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
    if is_super_admin?
      " - super admin"
    elsif is_admin?
      " - admin"
    else
      ""
    end
  end

  def is_super_admin?
    session[:role] == "super_admin"
  end

  def is_admin?
    session[:role] == "admin" || session[:role] == "super_admin"
  end

  def is_user?
    session[:role] == "user" || session[:role] == "admin" || session[:role] == "super_admin"
  end
  
  def get_uniqname(email)
    email.split("@").first
  end
  
end

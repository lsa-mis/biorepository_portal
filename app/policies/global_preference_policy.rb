class GlobalPreferencePolicy < ApplicationPolicy
  def index?
    is_developer?
  end

  def show?
    is_developer?
  end

  def create?
    is_developer?
  end

  def new?
    create?
  end

  def delete_preference?
    is_developer?
  end

  def app_prefs?
    is_super_admin?
  end

  def save_app_prefs?
    is_super_admin?
  end

end

class AppPreferencePolicy < ApplicationPolicy
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

  def update?
    is_developer?
  end
  
  def edit?
    update?
  end

  def destroy?
    is_developer?
  end

  def configure_prefs?
    is_admin?
  end

  def save_configured_prefs?
    is_admin?
  end

end

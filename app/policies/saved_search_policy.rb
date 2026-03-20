class SavedSearchPolicy < ApplicationPolicy
  
  def save_search?
    authenticated?
  end
  
  def index?
    true
  end

  def create?
    authenticated?
  end

  def update?
    is_owner? || is_admin?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    is_owner? || is_admin?
  end

  def reorder?
    is_owner? ||is_admin?
  end

  def move_up?
    is_owner? || is_admin?
  end

  def move_down?
    is_owner? || is_admin?
  end

end

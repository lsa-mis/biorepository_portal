class SavedSearchPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    authenticated?
  end

  def update?
    is_owner?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    is_owner?
  end

end

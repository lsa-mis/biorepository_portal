class SavedSearchPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    authenticated?
  end

  def update?
    authenticated?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    authenticated?
  end

end

class FaqPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    is_admin?
  end

  def update?
    is_admin?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    is_admin?
  end

  def reorder?
    is_admin?
  end

  def move_up?
    is_admin?
  end

  def move_down?
    is_admin?
  end
end

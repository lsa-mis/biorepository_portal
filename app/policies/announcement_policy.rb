class AnnouncementPolicy < ApplicationPolicy
  def index?
    is_admin?
  end

  def edit?
    is_admin?
  end

  def update?
    is_admin?
  end
end

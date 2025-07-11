class AnnouncementPolicy < ApplicationPolicy
  def index?
    is_super_admin?
  end

  def edit?
    is_super_admin?
  end

  def update?
    is_super_admin?
  end
end

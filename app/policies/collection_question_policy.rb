class CollectionQuestionPolicy < ApplicationPolicy
  def index?
    is_admin?
  end

  def show?
    is_admin?
  end

  def new?
    create?
  end

  def create?
    is_collection_admin? || is_super_admin?
  end

  def edit?
    update?
  end

  def update?
    is_collection_admin? || is_super_admin?
  end

  def destroy?
    is_collection_admin? || is_super_admin?
  end

  private

  def is_collection_admin?
    return false unless is_admin?
    return false unless @collection_ids.present?
    return false unless @record.present?
    return false unless @record.collection.present?
    return false unless @record.collection.admin_group.present?
    return false unless @collection_ids.include?(@record.collection.id)
    true
  end
end

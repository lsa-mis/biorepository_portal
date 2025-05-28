# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end

  def search?
    true
  end

  def create?
    is_super_admin?
  end

  def new?
    create?
  end

  def update?
    is_admin?
  end

  def edit?
    update?
  end

  def destroy?
    is_super_admin?
  end

  def import?
    is_super_admin? || is_collection_admin?
  end

  private

  def is_collection_admin?
    return false unless is_admin?
    return false unless @collection_ids.present?
    return false unless @record.present?
    return false unless @record.admin_group.present?
    return false unless @collection_ids.include?(@record.id)
    true 
  end
  
end

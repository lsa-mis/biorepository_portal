class Collection::CollectionQuestionPolicy < ApplicationPolicy

  def initialize(context, record)
    @user = context[:user]
    @role = context[:role]
    @collection_ids = context[:collection_ids]
    @collection = Collection.find(context[:params]["collection_id"].to_i)
    @record = record
  end

  def index?
    is_collection_admin? || is_super_admin?
  end

  def show?
    is_collection_admin? || is_super_admin?
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
    return false unless @collection_ids.include?(@collection.id)
    true
  end
end

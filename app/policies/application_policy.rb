# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :role, :collection_ids, :record

  def initialize(context, record)
    @user = context[:user]
    @role = context[:role]
    @unit_ids = context[:unit_ids]
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def is_admin?
    @role == "admin" || @role == "super_admin"
  end

  def is_super_admin?
    @role == "super_admin"
  end

end

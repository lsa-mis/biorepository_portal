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

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end

  private

    def is_admin?
      @role == "admin"
    end

    def is_super_admin?
      @role == "super_admin"
    end

end

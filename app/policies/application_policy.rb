# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :role, :collection_ids, :record

  def initialize(context, record)
    @user = context[:user]
    @role = context[:role]
    @collection_ids = context[:collection_ids]
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

  private

  def is_admin?
    @role == "admin" || @role == "super_admin" || @role == "developer"
  end

  def is_super_admin?
    @role == "super_admin" || @role == "developer"
  end

  def is_developer?
    @role == "developer"
  end

  def authenticated?
    @user.present?
  end

  def is_owner?
    return false unless authenticated?
    
    case @record
    when ActiveRecord::Relation
      # For relations, check if all records belong to the user
      @record.all? { |record| record.user_id == @user.id }
    else
      # For single records
      @record.user_id == @user.id
    end
  end

end

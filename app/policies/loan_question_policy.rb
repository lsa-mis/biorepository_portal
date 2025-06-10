# frozen_string_literal: true

class LoanQuestionPolicy < ApplicationPolicy

  def index?
    is_admin?
  end

  def new?
    create?
  end
  
  def create?
    is_super_admin?
  end

  def show?
    is_admin?
  end

  def edit?
    update?
  end

  def update?
    is_super_admin?
  end
  
  def destroy?
    is_super_admin?
  end

  private
  
end

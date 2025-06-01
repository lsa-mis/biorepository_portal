# frozen_string_literal: true

class LoanQuestionPolicy < ApplicationPolicy

  def index?
    is_admin?
  end

  def new?
    create?
  end
  
  def create?
    is_admin?
  end

  private
  
end

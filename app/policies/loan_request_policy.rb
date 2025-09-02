# frozen_string_literal: true

class LoanRequestPolicy < ApplicationPolicy

  def show?
    is_admin?
  end

  def new?
    user.present?
  end

  def step_two?
    user.present?
  end

  def step_three?
    user.present?
  end

  def step_four?
    user.present?
  end

  def step_five?
    user.present?
  end

  def send_loan_request?
    user.present?
  end

  private
  
end

class ReportPolicy < ApplicationPolicy
  def index?
    is_admin?
  end

  def information_requests_report?
    is_admin?
  end

  def loan_requests_report?
    is_admin?
  end

  def import_data_report?
    is_admin?
  end

end

class ReportsController < ApplicationController

  def index
    authorize :report, :index?

    @reports_list = [
      {title: "Information Requests", url: information_requests_report_reports_path, description: "This report shows list of Information Requests" },
      {title: "Loan Requests", url: loan_requests_report_reports_path, description: "This report shows list of Loan Requests" },
      ]
  end

  def information_requests_report
    authorize :report, :information_requests_report?
  end

  def loan_requests_report
    authorize :report, :loan_requests_report?
  end

  private

end
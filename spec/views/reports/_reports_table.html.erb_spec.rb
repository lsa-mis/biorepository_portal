require 'rails_helper'

RSpec.describe "reports/_reports_table", type: :view do
  it "uses the loaded request record for report links without mutating row data" do
    loan_request = instance_double(LoanRequest, id: 42)
    rows = [[loan_request, "Museum", "2026-07-08", "Ada Lovelace <ada@example.com>"]]

    assign(:data, rows)
    assign(:headers, ["View Request", "Collections", "Created At", "Submitted By"])
    assign(:request_link, true)
    assign(:url, "loan_request_path")

    allow(view).to receive(:loan_request_path).with(loan_request, return_to: request.fullpath).and_return("/loan_requests/42")

    expect(LoanRequest).not_to receive(:find)

    render partial: "reports/reports_table"

    expect(rendered).to include("/loan_requests/42")
    expect(rows).to eq([[loan_request, "Museum", "2026-07-08", "Ada Lovelace <ada@example.com>"]])
  end
end

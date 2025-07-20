class ReportsController < ApplicationController
  before_action :set_form_values, :collect_form_params

  def index
    authorize :report, :index?

    @reports_list = [
      {title: "Information Requests", url: information_requests_report_reports_path, description: "This report shows Information Requests statistics" },
      {title: "Loan Requests", url: loan_requests_report_reports_path, description: "This report shows Loan Requests statistics" },
      ]
  end

  # Design - For each new report:
  # 1) run the logic / activerecord query based on params
  # 2) if there is no record returned, do none of the below
  # 3) define a title for the report: @title
  # 4) calculate summary metrics in a hash of description:value pairs : @metrics
  # 5) for a basic report:
  #   a) define an array of headers/column titles: @headers
  #   b) convert the query results into an array of arrays in order same as headers: @data
  # 6) for a grouped pivot-table report (w/ dates as columns):
  #   a) set @grouped = true
  #   b) define an array of date headers: @date_headers
  #   c) define an array of all headers (indluding date headers): @headers
  #   d) convert the query results into a grouped hash of hashes: @data
  #     i) the first key should be an array of 'grouped' keys, like for e.g [zone, building, room]
  #     ii) the second key should be the date
  #     iii) the value should be the cell value
  #     iv) for e.g: @data[[Zone, Building, Room]][Date] = Value

  def information_requests_report
    authorize :report, :information_requests_report?
    if params[:commit]
      start_time, end_time, collection_id = collect_form_params
      information_requests = InformationRequest.where(created_at: start_time..end_time).order(created_at: :desc)
      information_requests = information_requests.where("collection_ids @> ARRAY[?]::integer[]", collection_id) if collection_id.present?

      if information_requests.any?
        @title = "Information Requests Report"
        @metrics = {
          'Total Information Requests' => information_requests.count,
        }
        @headers = ["Request ID", "Collections", "Created At", "Submitted By", "Message"]
        @request_link = true
        @url = "information_request_path"
        @model_class = "InformationRequest"
        @data = information_requests.map do |request|
          [request.id, get_collections(request), request.created_at.strftime("%Y-%m-%d"), show_user_name_by_id(request.user_id), request.question.to_plain_text]
        end
      else
        @data = nil
      end

      respond_to do |format|
        format.html
        format.csv { send_data csv_data, filename: 'information_requests_report.csv', type: 'text/csv' }
      end
    end

  end

  def loan_requests_report
    authorize :report, :loan_requests_report?
    if params[:commit]
      start_time, end_time, collection_id = collect_form_params
      loan_requests = LoanRequest.where(created_at: start_time..end_time).order(created_at: :desc)
      loan_requests = loan_requests.where("collection_ids @> ARRAY[?]::integer[]", collection_id) if collection_id.present?

      if loan_requests.any?
        @title = "Loan Requests Report"
        @metrics = {
          'Total Loan Requests' => loan_requests.count,
          'Total Items Requested' => loan_requests.sum { |record| record.checkout_items.length }
        }
        @headers = ["Request ID", "Collections", "Created At", "Submitted By"]
        @request_link = true
        @url = "loan_request_path"
        @model_class = "LoanRequest"
        @data = loan_requests.map do |request|
          [request.id, get_collections(request), request.created_at.strftime("%Y-%m-%d"), show_user_name_by_id(request.user_id)]
        end
      else
        @data = nil
      end

      respond_to do |format|
        format.html
        format.csv { send_data csv_data, filename: 'loan_requests_report.csv', type: 'text/csv' }
      end
    end
  end

  private

  def set_form_values
    @collections = Collection.all.order(:division).map { |c| [c.division, c.id] }
  end

  def collect_form_params
    start_time = if params[:from].present?
      begin
        Date.strptime(params[:from], '%Y-%m-%d').beginning_of_day
      rescue ArgumentError
        1.year.ago.beginning_of_day # Fallback to a default value
      end
    else
      1.year.ago.beginning_of_day
    end
    end_time = if params[:to].present?
      begin
        Date.strptime(params[:to], '%Y-%m-%d').end_of_day
      rescue ArgumentError
        Time.current.end_of_day # Fallback to a default value
      end
    else
      Time.current.end_of_day
    end
    collection_id = params[:collection_id].presence || nil
    [start_time, end_time, collection_id]
  end

  def get_collections(request)
    collection_ids = request.collection_ids
    collections = Collection.where(id: collection_ids).pluck(:division).uniq
    collections.join(', ')
  end

  def csv_data
    CSV.generate(headers: true) do |csv|
      next csv << ["No data found"] if !@data

      csv << [@title]
      csv << []
      @metrics && @metrics.each { |desc, value| csv << [desc, value] }

      if @grouped
        @data.each do |group, pivot_table|
          csv << []
          csv << (@group_link && group.is_a?(Array) ? ["#{group[0]} #{group[1].room_number}"] : [group])
          csv << @headers
          pivot_table.each do |keys, record|
            keys = [keys[0][0]] + keys[1..] if @room_link && keys[0].is_a?(Array)
            csv << keys + @date_headers.map { |date| record[date] }
          end          
        end
      else
        csv << []
        csv << @headers
        @data.each do |row|
          if @room_link
            row[0] = row[0].request_id
          end
          csv << row
        end
      end
    end
  end

end
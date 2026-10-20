require 'rails_helper'

RSpec.describe 'Metrics count tables', type: :request do
  let(:birds) { FactoryBot.create(:collection, division: 'Birds', admin_group: 'birds_admins') }
  let(:fish) { FactoryBot.create(:collection, division: 'Fish', admin_group: 'fish_admins') }

  before do
    FactoryBot.create(:item, collection: fish, recorded_by: 'Zed')
    FactoryBot.create_list(:item, 2, collection: birds, recorded_by: 'Amy')
    FactoryBot.create_list(:item, 3, collection: fish, recorded_by: 'Bob')
  end

  def table_rows(caption)
    table = Nokogiri::HTML(response.body).css('table').find { |t| t.at_css('caption').text == caption }
    table.css('tbody tr').map { |row| [row.at_css('th').text, row.at_css('td').text] }
  end

  def header_sort(caption)
    table = Nokogiri::HTML(response.body).css('table').find { |t| t.at_css('caption').text == caption }
    table.css('thead th').map { |th| th['aria-sort'] }
  end

  it 'renders sortable headers with rows sorted by label' do
    get metrics_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="sortable-table"')
    expect(table_rows('Number of items per collection')).to eq([['Birds', '2'], ['Fish', '4']])
    expect(header_sort('Number of items per collection')).to eq(%w[ascending none])
  end

  it 'renders the recorder table sorted by number of items' do
    get metrics_path
    expect(table_rows('Number of items by recorder')).to eq([['Bob', '3'], ['Amy', '2'], ['Zed', '1']])
    expect(header_sort('Number of items by recorder')).to eq(%w[none descending])
  end
end

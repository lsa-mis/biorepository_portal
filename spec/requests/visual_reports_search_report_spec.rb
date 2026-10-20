require 'rails_helper'

RSpec.describe 'VisualReports index with a search', type: :request do
  let(:collection) { FactoryBot.create(:collection) }
  let!(:robin) { FactoryBot.create(:item, collection: collection, country: 'USA', recorded_by: 'Amy') }
  let!(:trout) { FactoryBot.create(:item, collection: collection, country: 'Canada', recorded_by: 'Bob') }
  let(:robin_search) do
    { q: { groupings: { '0' => { '0' => { 'field' => 'identifications_scientific_name_i_cont_any', 'value' => 'turdus' } } } } }
  end

  before do
    # Two matching identifications on one item must still count the item once
    FactoryBot.create(:identification, item: robin, scientific_name: 'Turdus migratorius', current: true)
    FactoryBot.create(:identification, item: robin, scientific_name: 'Turdus americanus', current: false)
    FactoryBot.create(:identification, item: trout, scientific_name: 'Salvelinus fontinalis', current: true)
  end

  def table_rows(caption)
    table = Nokogiri::HTML(response.body).css('table').find { |t| t.at_css('caption').text == caption }
    table.css('tbody tr').map { |row| [row.at_css('th').text, row.at_css('td').text] }
  end

  it 'reports only items matching the search' do
    get visual_reports_path, params: robin_search
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Search Results in All Collections')
    expect(response.body).to include('Scientific Name: "turdus"')
    expect(response.body).to include("1 item from #{collection.division}.")
    expect(response.body).to include('Back to Search Results')
    expect(table_rows('Number of items per country')).to eq([['USA', '1']])
    expect(table_rows('Number of items by recorder')).to eq([['Amy', '1']])
  end

  it 'counts only items matching the search by collection' do
    other = FactoryBot.create(:collection, division: 'Other Division', admin_group: 'other_admins')
    FactoryBot.create(:item, collection: other)
    get visual_reports_path, params: robin_search
    expect(response.body).to include('Search Results by Collection')
    expect(table_rows('Number of items per collection')).to eq([[collection.division, '1'], ['Other Division', '0']])
  end

  it 'reports all items without a search' do
    get visual_reports_path
    expect(response.body).to include('Items in All Collections')
    expect(response.body).to include("2 items from #{collection.division}.")
    expect(response.body).not_to include('Back to Search Results')
    expect(table_rows('Number of items per country')).to eq([['Canada', '1'], ['USA', '1']])
  end

  it 'links to the metrics from the search results page' do
    get search_items_path, params: robin_search
    link = Nokogiri::HTML(response.body).css('a').find { |a| a.text.include?('Metrics') && a['href'].include?('?q') }
    expect(link['href']).to start_with(visual_reports_path + '?q')
    get link['href']
    expect(table_rows('Number of items per country')).to eq([['USA', '1']])
  end
end

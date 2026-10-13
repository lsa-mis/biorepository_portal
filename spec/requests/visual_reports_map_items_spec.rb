require 'rails_helper'

RSpec.describe 'VisualReports map_items', type: :request do
  let(:collection) { FactoryBot.create(:collection) }
  let!(:bird_item) { FactoryBot.create(:item, collection: collection, catalog_number: 'BIRD-001') }
  let!(:fish_item) { FactoryBot.create(:item, collection: collection, catalog_number: 'FISH-001') }

  def map_item_ids
    JSON.parse(response.body).map(&:first)
  end

  it 'returns all items without a search query' do
    get map_items_path(format: :json)
    expect(response).to have_http_status(:ok)
    expect(map_item_ids).to contain_exactly(bird_item.id, fish_item.id)
  end

  it 'returns only items matching a search query' do
    get map_items_path(format: :json), params: { q: { catalog_number_cont: 'BIRD' } }
    expect(map_item_ids).to contain_exactly(bird_item.id)
  end

  it 'returns only items matching advanced search groupings' do
    params = { q: { groupings: { '0' => { '0' => { 'field' => 'catalog_number_i_cont_any', 'value' => 'fish' } } } } }
    get map_items_path(format: :json), params: params
    expect(map_item_ids).to contain_exactly(fish_item.id)
  end

  it 'passes the search query to the map data url' do
    get map_items_path, params: { q: { catalog_number_cont: 'BIRD' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Search Results Map')
    expect(response.body).to include(CGI.escapeHTML(map_items_path(q: { catalog_number_cont: 'BIRD' }, format: :json)))
  end

  it 'shows the selected filters and item counts for an advanced search' do
    FactoryBot.create(:item, collection: collection, catalog_number: 'FISH-002', decimal_latitude: nil, decimal_longitude: nil)
    params = { q: { groupings: { '0' => { '0' => { 'field' => 'catalog_number_i_cont_any', 'value' => 'fish' } } } } }
    get map_items_path, params: params
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Catalog Number: "fish"')
    expect(response.body).to include("2 items from #{collection.division}.")
    expect(response.body).to include('1 with coordinates shown on the map.')
    expect(response.body).not_to include('search#removeFilter')
  end

  it 'shows the total for all items without a search query' do
    get map_items_path
    expect(response.body).to include("2 items from #{collection.division}.")
    expect(response.body).not_to include('Back to Search Results')
  end
end

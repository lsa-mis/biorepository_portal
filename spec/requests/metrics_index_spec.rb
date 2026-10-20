require 'rails_helper'

RSpec.describe 'Metrics index', type: :request do
  let(:collection) { FactoryBot.create(:collection) }
  let!(:item) { FactoryBot.create(:item, collection: collection, country: 'USA') }

  it 'shows all reports on one page, starting with the map' do
    get metrics_path
    expect(response).to have_http_status(:ok)

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('h1').text).to eq('Metrics')
    expect(doc.css('.container-fluid section > h2').map(&:text)).to eq(['Items Map', 'Items by Collection', 'Items in All Collections'])
    expect(doc.at_css('[data-controller="items-map"]')['data-items-map-url-value']).to eq(map_items_path(format: :json))

    captions = doc.css('table caption').map(&:text)
    expect(captions).to include('Number of items per collection', 'Number of items per country')
  end
end

require 'rails_helper'

RSpec.describe 'VisualReports count table links', type: :request do
  let(:birds) { FactoryBot.create(:collection, division: 'Birds', admin_group: 'birds_admins') }
  let(:fish) { FactoryBot.create(:collection, division: 'Fish', admin_group: 'fish_admins') }

  before do
    robin = FactoryBot.create(:item, collection: birds, country: 'USA', recorded_by: 'Amy', event_date_start: '2001-03-04', event_date_end: nil)
    FactoryBot.create(:preparation, item: robin, prep_type: 'Skin')
    FactoryBot.create(:preparation, item: robin, prep_type: 'Skeleton')
    FactoryBot.create(:item, collection: birds, country: 'Canada', recorded_by: 'Bob', event_date_start: '2001-12-31', event_date_end: '2002-01-02')
    trout = FactoryBot.create(:item, collection: fish, country: 'USA', recorded_by: 'Amy', event_date_start: '2002-01-01')
    FactoryBot.create(:preparation, item: trout, prep_type: 'Skin')
    FactoryBot.create(:item, collection: fish, country: '', recorded_by: nil, event_date_start: nil)
    FactoryBot.create(:item, collection: fish, country: 'UsA', recorded_by: 'Amy', event_date_start: '2002-05-05')
  end

  # [label, count, href] for each row of each count table on the current page
  def table_rows
    Nokogiri::HTML(response.body).css('table.visual_report_table tbody tr').map do |row|
      [row.at_css('th').text.strip, row.at_css('td').text.delete(',').to_i, row.at_css('th a')&.[]('href')]
    end
  end

  def search_total
    text = Nokogiri::HTML(response.body).at_css('#items_result_list')&.text.to_s
    return 0 if text.include?('No items available')
    # Kaminari: "Displaying 1 item", "Displaying all 5 items" or "Displaying items 1 - 25 of 80 in total"
    text.squish[/Displaying (?:all )?([\d,]+) items?|of ([\d,]+) in total/]
    (Regexp.last_match(1) || Regexp.last_match(2)).delete(',').to_i
  end

  def expect_links_to_match_counts(report_path)
    get report_path
    rows = table_rows
    linked = rows.select { |_label, _count, href| href }
    expect(linked).not_to be_empty
    linked.each do |label, count, href|
      get href
      expect(search_total).to eq(count), "#{label}: row shows #{count}, search found #{search_total} (#{href})"
    end
    rows
  end

  it 'links each collection and preparation type row to a search with the same number of items' do
    rows = expect_links_to_match_counts(items_by_collection_visual_reports_path)
    expect(rows.map(&:first)).to include('Birds', 'Fish', 'Skin', 'Skeleton', 'No preparation')
    expect(rows.find { |label, *| label == 'No preparation' }.last).to be_nil
  end

  it 'links each year, country and recorder row to a search with the same number of items' do
    rows = expect_links_to_match_counts(items_in_all_collections_visual_reports_path)
    expect(rows.select { |label, *| label == 'Unknown' }.map(&:last)).to all(be_nil)
  end

  it 'keeps the report search in the row links' do
    search = { q: { groupings: { '0' => { '0' => { 'field' => 'recorded_by_i_cont_any', 'value' => 'amy' } } } } }
    get items_in_all_collections_visual_reports_path, params: search
    usa = table_rows.find { |label, *| label == 'USA' }
    expect(usa[1]).to eq(3)
    get usa.last
    expect(search_total).to eq(3)
    expect(response.body).to include('Recorded By: &quot;amy&quot;').or include('Recorded By: "amy"')
  end

  it 'groups countries that differ only in case, as the search does' do
    get items_in_all_collections_visual_reports_path
    expect(table_rows.select { |label, *| label.casecmp?('usa') }.map { |label, count, _| [label, count] }).to eq([['USA', 3]])
  end
end

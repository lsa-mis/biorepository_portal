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

  it 'adds blank countries and a literal Unknown country into one Unknown row' do
    FactoryBot.create(:item, collection: fish, country: 'Unknown')
    FactoryBot.create(:item, collection: fish, country: nil)
    get items_in_all_collections_visual_reports_path
    country_table = Nokogiri::HTML(response.body).css('table').find { |t| t.at_css('caption').text == 'Number of items per country' }
    unknown = country_table.css('tbody tr').select { |row| row.at_css('th').text == 'Unknown' }
    expect(unknown.map { |row| [row.at_css('td').text, row.at_css('th a')] }).to eq([['3', nil]])
  end

  describe 'preparation types' do
    let(:mammals) { FactoryBot.create(:collection, division: 'Mammals', admin_group: 'mammals_admins') }

    def preparation_rows
      get items_by_collection_visual_reports_path
      table = Nokogiri::HTML(response.body).css('table').find { |t| t.at_css('caption').text.end_with?('for Mammals') }
      table.css('tbody tr').map { |row| [row.at_css('th').text, row.at_css('td').text.to_i, row.at_css('th a')&.[]('href')] }
    end

    before do
      # Two items with different spellings, and one item with both spellings
      [['Skin'], ['skin'], ['Skin', 'SKIN']].each do |types|
        item = FactoryBot.create(:item, collection: mammals)
        types.each { |type| FactoryBot.create(:preparation, item: item, prep_type: type) }
      end
      # One item without preparations and one with a literal "No preparation" type
      FactoryBot.create(:item, collection: mammals)
      FactoryBot.create(:preparation, item: FactoryBot.create(:item, collection: mammals), prep_type: 'No preparation')
    end

    it 'combines case variants, counting each item once, and links to a search with the same number of items' do
      skin = preparation_rows.find { |label, *| label.casecmp?('skin') }
      expect(preparation_rows.count { |label, *| label.casecmp?('skin') }).to eq(1)
      expect(skin[1]).to eq(3)
      get skin.last
      expect(search_total).to eq(3)
    end

    it 'combines items without a preparation type and a literal No preparation type into one unlinked row' do
      expect(preparation_rows.select { |label, *| label == 'No preparation' }).to eq([['No preparation', 2, nil]])
    end
  end

  describe 'filters without a search form control' do
    # Fields the browser would submit from the search form (as when Sort or Switch View changes)
    def submitted_form_fields(sort:)
      form = Nokogiri::HTML(response.body).at_css('form#search-form')
      fields = form.css('input[name]').filter_map do |input|
        next if %w[checkbox radio].include?(input['type']) && !input.key?('checked')
        next if %w[submit button].include?(input['type'])
        [input['name'], input['value'].to_s]
      end
      fields += form.css('select[name]').map do |select|
        [select['name'], select.name == 'select' && select['name'] == 'sort' ? sort : (select.at_css('option[selected]') || select.at_css('option'))&.[]('value').to_s]
      end
      fields
    end

    def resubmit_with_sort(sort)
      query = submitted_form_fields(sort: sort).map { |name, value| "#{CGI.escape(name)}=#{CGI.escape(value)}" }.join('&')
      get "#{search_items_path}?#{query}"
    end

    {
      'year' => ['2001', { 'event_date_start_lteq' => '2001-12-31' }],
      'recorder' => ['Amy', { 'recorded_by_eq' => 'Amy' }]
    }.each do |kind, (label, hidden)|
      it "keeps the #{kind} filter when the search form is resubmitted, and lets its badge remove it" do
        get items_in_all_collections_visual_reports_path
        _label, count, href = table_rows.find { |row_label, *| row_label == label }
        get href
        expect(search_total).to eq(count)

        key, value = hidden.first
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css("form#search-form input[type=hidden]#q_#{key}")&.[]('value')).to eq(value)
        expect(doc.at_css("button[data-action='click->search#removeFilter'][data-key='#{key}']")&.[]('data-value')).to eq(value)

        resubmit_with_sort('items.catalog_number desc')
        expect(search_total).to eq(count)
      end
    end

    it 'does not render the hidden fields for other searches' do
      get search_items_path
      expect(response.body).not_to include('q_event_date_start_lteq', 'q_recorded_by_eq')
    end
  end

  describe 'rows of a report filtered by a search' do
    amy = { 'groupings' => { '0' => { '0' => { 'field' => 'recorded_by_i_cont_any', 'value' => 'amy' } } } }
    {
      'a start date lower bound' => { 'event_date_start_gteq' => '2001-06-01' },
      'a start date upper bound' => { 'event_date_start_lteq' => '2002-03-01' },
      'both bounds and an advanced search group' => amy.merge('event_date_start_gteq' => '2001-03-01', 'event_date_start_lteq' => '2002-03-01'),
      'a country list' => { 'country_case_insensitive_in' => ['usa', 'canada'] }
    }.each do |description, search|
      it "link to searches matching both the report search and the row for #{description}" do
        expect_links_to_match_counts(items_in_all_collections_visual_reports_path(q: search))
      end
    end

    it 'keeps the later start date when the search starts within the row year' do
      get items_in_all_collections_visual_reports_path(q: { event_date_start_gteq: '2001-06-01' })
      _label, count, href = table_rows.find { |label, *| label == '2001' }
      expect(count).to eq(1)
      expect(Rack::Utils.parse_nested_query(URI(href).query)['q']).to include('event_date_start_gteq' => '2001-06-01', 'event_date_start_lteq' => '2001-12-31')
    end
  end
end

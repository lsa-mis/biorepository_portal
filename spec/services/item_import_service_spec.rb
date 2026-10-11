require 'rails_helper'

RSpec.describe ItemImportService do
  let(:collection) { create(:collection) }
  let(:user) { build(:user) }
  let(:csv_file) { Tempfile.new(['occurrence', '.csv']) }

  before do
    [
      ['occurrenceID', 'occurrence_id'],
      ['catalogNumber', 'catalog_number'],
      ['month', 'month_ignore'],
      ['eventDate', 'event_date'],
      ['decimalLatitude', 'decimal_latitude'],
      ['decimalLongitude', 'decimal_longitude'],
      ['individualCount', 'individual_count'],
      ['preparations', 'preparations', 'preparations']
    ].each do |specify_field, rails_field, table|
      create(:map_field, specify_field: specify_field, rails_field: rails_field, table: table || 'items')
    end
  end

  after { csv_file.close! }

  def import(rows, header: %w[occurrenceID catalogNumber month eventDate decimalLatitude decimalLongitude individualCount preparations])
    csv_file.write(CSV.generate { |csv| ([header] + rows).each { |row| csv << row } })
    csv_file.flush
    upload = Rack::Test::UploadedFile.new(csv_file.path, 'text/csv', original_filename: 'occurrence.csv')
    described_class.new(upload, collection.id, user).call
  end

  it 'creates items with their preparations' do
    result = import([['occ-1', 'CAT-1', '9', '2024-09-16', '42.28', '-83.74', '2', 'Whole - 1: BC1: in ethanol']])

    item = Item.find_by!(occurrence_id: 'occ-1')
    expect(result[:errors]).to eq(0)
    expect(item).to have_attributes(catalog_number: 'CAT-1', decimal_latitude: 42.28, decimal_longitude: -83.74,
                                    event_date_start: Date.new(2024, 9, 16), individual_count: 2)
    expect(item.preparations.pluck(:prep_type, :count, :barcode)).to eq([['Whole', 1, 'BC1']])
  end

  it 'reads values from the matching column when a header is not mapped' do
    header = %w[occurrenceID unmappedColumn catalogNumber eventDate decimalLatitude decimalLongitude individualCount preparations]
    import([['occ-1', 'junk', 'CAT-1', '2024-09-16', '42.28', '-83.74', '2', 'Whole']], header: header)

    expect(Item.find_by!(occurrence_id: 'occ-1')).to have_attributes(catalog_number: 'CAT-1', decimal_latitude: 42.28)
  end

  it 'stores blank numeric fields as nil instead of zero' do
    import([['occ-1', 'CAT-1', '', '', '', '', '', 'Whole']])

    expect(Item.find_by!(occurrence_id: 'occ-1')).to have_attributes(decimal_latitude: nil, decimal_longitude: nil,
                                                                      individual_count: nil, event_date_start: nil)
  end

  it 'parses a month/day/two-digit-year date as a single date, not a range' do
    import([['occ-1', 'CAT-1', '9', '9/16/24', '', '', '', 'Whole']])

    expect(Item.find_by!(occurrence_id: 'occ-1')).to have_attributes(event_date_start: Date.new(2024, 9, 16), event_date_end: nil)
  end

  it 'puts a two-digit year that would be in the future in the previous century' do
    import([['occ-1', 'CAT-1', '5', '5/3/65', '', '', '', 'Whole']])

    expect(Item.find_by!(occurrence_id: 'occ-1').event_date_start).to eq(Date.new(1965, 5, 3))
  end

  it 'parses an ISO date range' do
    import([['occ-1', 'CAT-1', '9', '2024-09-16/2024-09-20', '', '', '', 'Whole']])

    expect(Item.find_by!(occurrence_id: 'occ-1')).to have_attributes(event_date_start: Date.new(2024, 9, 16),
                                                                      event_date_end: Date.new(2024, 9, 20))
  end

  it 'reports an invalid event date' do
    result = import([['occ-1', 'CAT-1', '9', 'not a date', '', '', '', 'Whole']])

    expect(result[:errors]).to eq(1)
    expect(result[:note].join).to include("Invalid eventDate format")
  end

  it 'removes items that are not in the file and keeps items that are' do
    kept = create(:item, collection: collection, occurrence_id: 'occ-1')
    removed = create(:item, collection: collection, occurrence_id: 'occ-2')

    import([['occ-1', 'CAT-1', '', '', '', '', '', 'Whole']])

    expect(Item.exists?(kept.id)).to be(true)
    expect(Item.exists?(removed.id)).to be(false)
  end

  it 'does not delete an existing item whose update fails' do
    item = create(:item, collection: collection, occurrence_id: 'occ-1')
    allow_any_instance_of(Item).to receive(:save).and_return(false)

    result = import([['occ-1', 'CAT-1', '', '', '', '', '', 'Whole']])

    expect(result[:errors]).to eq(1)
    expect(Item.exists?(item.id)).to be(true)
  end

  it 'removes an existing item whose row has no preparations' do
    item = create(:item, collection: collection, occurrence_id: 'occ-1')

    import([['occ-1', 'CAT-1', '', '', '', '', '', '']])

    expect(Item.exists?(item.id)).to be(false)
  end

  it 'handles a file saved with a UTF-8 byte order mark' do
    csv_file.write("﻿")
    import([['occ-1', 'CAT-1', '', '', '', '', '', 'Whole']])

    expect(Item.find_by(occurrence_id: 'occ-1')).to be_present
  end
end

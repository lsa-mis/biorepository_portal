require 'rails_helper'

RSpec.describe IdentificationImportService do
  let(:collection) { create(:collection) }
  let(:user) { build(:user) }
  let(:item) { create(:item, collection: collection, occurrence_id: 'occ-1') }
  let(:csv_file) { Tempfile.new(['identification', '.csv']) }

  before do
    [
      ['occurrenceID', 'occurrence_id_ignore'],
      ['isCurrent', 'current'],
      ['scientificName', 'scientific_name']
    ].each do |specify_field, rails_field|
      create(:map_field, specify_field: specify_field, rails_field: rails_field, table: 'identifications')
    end
  end

  after { csv_file.close! }

  def import(rows)
    csv_file.write(CSV.generate { |csv| ([%w[occurrenceID isCurrent scientificName]] + rows).each { |row| csv << row } })
    csv_file.flush
    upload = Rack::Test::UploadedFile.new(csv_file.path, 'text/csv', original_filename: 'identification.csv')
    described_class.new(upload, collection.id, user).call
  end

  it 'replaces the identifications of an item' do
    create(:identification, item: item, scientific_name: 'Old name')

    result = import([['occ-1', 'true', 'New name'], ['occ-1', 'false', 'Other name']])

    expect(result[:errors]).to eq(0)
    expect(item.identifications.order(:scientific_name).pluck(:scientific_name, :current))
      .to eq([['New name', true], ['Other name', false]])
  end

  it 'keeps existing identifications when a new one fails to save' do
    create(:identification, item: item, scientific_name: 'Old name')
    allow_any_instance_of(Identification).to receive(:save).and_return(false)

    result = import([['occ-1', 'true', 'New name']])

    expect(result[:errors]).to eq(1)
    expect(item.identifications.pluck(:scientific_name)).to eq(['Old name'])
  end

  it 'keeps the default current value for an unrecognized isCurrent value' do
    item
    import([['occ-1', 'maybe', 'New name']])

    expect(item.identifications.pluck(:current)).to eq([false])
  end

  it 'skips occurrence ids that are not in the collection' do
    result = import([['unknown', 'true', 'New name']])

    expect(result[:errors]).to eq(0)
    expect(Identification.count).to eq(0)
  end
end

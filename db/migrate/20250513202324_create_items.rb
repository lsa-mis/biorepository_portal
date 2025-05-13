class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :occurrence_id
      t.string :catalog_number
      t.date :modified
      t.string :recorded_by
      t.integer :individual_count
      t.string :sex
      t.string :life_stage
      t.string :reproductive_condition
      t.string :vitality
      t.string :other_catalog_numbers
      t.text :occurrence_remarks
      t.text :organism_remarks
      t.string :associated_sequences
      t.string :field_number
      t.date :event_date_start
      t.date :event_date_end
      t.string :verbatim_event_date
      t.string :sampling_protocol
      t.text :event_remarks
      t.string :continent
      t.string :country
      t.string :state_province
      t.string :county
      t.string :locality
      t.string :verbatim_locality
      t.string :verbatim_elevation
      t.float :minimum_elevation_in_meters
      t.float :maximum_elevation_in_meters
      t.float :decimal_latitude
      t.float :decimal_longitude
      t.float :coordinate_uncertainty_in_meters
      t.string :verbatim_coordinates
      t.string :georeferenced_by
      t.date :georeferenced_date
      t.string :geodetic_datum
      t.string :georeference_protocol
      t.boolean :archived
      t.references :collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end

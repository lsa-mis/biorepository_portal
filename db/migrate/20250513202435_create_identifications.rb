class CreateIdentifications < ActiveRecord::Migration[8.0]
  def change
    create_table :identifications do |t|
      t.string :type_status
      t.string :identified_by
      t.string :date_identified
      t.text :identification_remarks
      t.string :scientific_name
      t.string :scientific_name_authorship
      t.string :kingdom
      t.string :phylum
      t.string :class_name
      t.string :order_name
      t.string :family
      t.string :genus
      t.string :specific_epithet
      t.string :infraspecific_epithet
      t.integer :taxon_rank
      t.string :vernacular_name
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end
  end
end

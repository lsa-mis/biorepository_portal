class CreateItemImportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :item_import_logs do |t|
      t.datetime :date
      t.string :user
      t.integer :collection_id
      t.string :status
      t.string :note, array: true, default: []

      t.timestamps
    end
  end
end

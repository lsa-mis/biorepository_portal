class CreateItemImportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :item_import_logs do |t|
      t.datetime :date
      t.string :user
      t.string :status
      t.string :note

      t.timestamps
    end
  end
end

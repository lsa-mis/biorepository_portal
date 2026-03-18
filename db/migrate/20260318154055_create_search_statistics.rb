class CreateSearchStatistics < ActiveRecord::Migration[8.1]
  def change
    create_table :search_statistics do |t|
      t.string :field_name, null: false
      t.string :field_label, null: false
      t.string :field_value, null: false

      t.timestamps
    end
  end
end

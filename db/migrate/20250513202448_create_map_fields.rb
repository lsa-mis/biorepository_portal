class CreateMapFields < ActiveRecord::Migration[8.0]
  def change
    create_table :map_fields do |t|
      t.string :table
      t.string :specify_field
      t.string :rails_field
      t.string :caption

      t.timestamps
    end
  end
end

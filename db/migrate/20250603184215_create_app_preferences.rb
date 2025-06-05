class CreateAppPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :app_preferences do |t|
      t.string :name
      t.string :description
      t.integer :pref_type
      t.string :value
      t.belongs_to :collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end

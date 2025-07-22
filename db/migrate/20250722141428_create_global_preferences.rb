class CreateGlobalPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :global_preferences do |t|
      t.string :name
      t.string :description
      t.integer :pref_type
      t.string :value

      t.timestamps
    end
  end
end

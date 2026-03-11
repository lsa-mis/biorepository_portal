class CreateSavedSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :filters
      t.boolean :global, null: false, default: false
      t.jsonb :search_params, null: false, default: {}

      t.timestamps
    end
  end
end

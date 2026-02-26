class CreateSavedSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.boolean :global, default: false
      t.jsonb :search_params

      t.timestamps
    end
  end
end

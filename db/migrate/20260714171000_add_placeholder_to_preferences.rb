class AddPlaceholderToPreferences < ActiveRecord::Migration[8.0]
  def change
    add_column :app_preferences, :placeholder, :string
    add_column :global_preferences, :placeholder, :string
  end
end

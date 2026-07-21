class AllowAppPreferencesWithoutCollections < ActiveRecord::Migration[8.1]
  def change
    change_column_null :app_preferences, :collection_id, true
  end
end

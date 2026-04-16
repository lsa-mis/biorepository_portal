class AddSearchSessionIdToSearchStatistics < ActiveRecord::Migration[8.1]
  def change
    add_column :search_statistics, :search_session_id, :string
  end
end

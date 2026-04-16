class AddIndexesToSearchStatistics < ActiveRecord::Migration[8.1]
  def change
    add_index :search_statistics, :created_at
    add_index :search_statistics, :search_session_id
    add_index :search_statistics, [:search_session_id, :created_at]
  end
end

class AddUniqueIndexAndNotNullToItemsOccurrenceId < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_items_on_collection_id_and_occurrence_id"

  def up
    null_count = execute("SELECT COUNT(*) AS count FROM items WHERE occurrence_id IS NULL").first["count"].to_i
    if null_count.positive?
      raise ActiveRecord::IrreversibleMigration,
            "Cannot set items.occurrence_id to NOT NULL: #{null_count} row(s) have NULL occurrence_id"
    end

    duplicate_groups = execute(<<~SQL)
      SELECT collection_id, occurrence_id, COUNT(*) AS duplicate_count
      FROM items
      GROUP BY collection_id, occurrence_id
      HAVING COUNT(*) > 1
      LIMIT 5
    SQL

    if duplicate_groups.any?
      examples = duplicate_groups.map do |row|
        "(collection_id=#{row['collection_id']}, occurrence_id=#{row['occurrence_id']}, count=#{row['duplicate_count']})"
      end.join(", ")

      raise ActiveRecord::IrreversibleMigration,
            "Cannot add unique index on items(collection_id, occurrence_id): duplicates exist. Example groups: #{examples}"
    end

    change_column_null :items, :occurrence_id, false

    add_index :items,
              [:collection_id, :occurrence_id],
              unique: true,
              name: INDEX_NAME,
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :items, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
    change_column_null :items, :occurrence_id, true
  end
end
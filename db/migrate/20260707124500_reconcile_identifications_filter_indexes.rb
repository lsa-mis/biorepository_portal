class ReconcileIdentificationsFilterIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :identifications,
              :class_name,
              name: "idx_identifications_current_class",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              :family,
              name: "idx_identifications_current_family",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              :genus,
              name: "idx_identifications_current_genus",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              :kingdom,
              name: "idx_identifications_current_kingdom",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              :order_name,
              name: "idx_identifications_current_order",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              :phylum,
              name: "idx_identifications_current_phylum",
              where: "current = true",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              [:item_id, :current],
              name: "idx_identifications_item_current",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :identifications,
              [:item_id, :current, :kingdom, :phylum, :class_name, :order_name, :family, :genus],
              name: "idx_identifications_taxonomy_covering",
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :identifications, name: "idx_identifications_current_class", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_current_family", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_current_genus", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_current_kingdom", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_current_order", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_current_phylum", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_item_current", algorithm: :concurrently, if_exists: true
    remove_index :identifications, name: "idx_identifications_taxonomy_covering", algorithm: :concurrently, if_exists: true
  end
end
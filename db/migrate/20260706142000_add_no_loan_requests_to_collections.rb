class AddNoLoanRequestsToCollections < ActiveRecord::Migration[8.1]
  def up
    add_column :collections, :no_loan_requests, :boolean, null: false, default: false

    execute <<~SQL.squish
      UPDATE collections
      SET no_loan_requests = TRUE
      WHERE id IN (
        SELECT collection_id
        FROM app_preferences
        WHERE name = 'no_loan_requests'
          AND value IN ('1', 'true', 't')
      )
    SQL
  end

  def down
    remove_column :collections, :no_loan_requests
  end
end

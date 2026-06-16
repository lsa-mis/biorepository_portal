class AddPrepTypeIndexToPreparations < ActiveRecord::Migration[7.1]
  def change
    add_index :preparations, :prep_type, name: "idx_preparations_prep_type"
  end
end

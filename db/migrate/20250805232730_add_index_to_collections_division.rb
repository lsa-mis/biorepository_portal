class AddIndexToCollectionsDivision < ActiveRecord::Migration[8.0]
  def change
    add_index :collections, :division
  end
end

class AddPositionToCollectionQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_questions, :position, :integer
    add_index :collection_questions, :position
  end
end

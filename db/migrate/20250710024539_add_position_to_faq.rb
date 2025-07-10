class AddPositionToFaq < ActiveRecord::Migration[8.0]
  def change
    add_column :faqs, :position, :integer
    add_index :faqs, :position
  end
end

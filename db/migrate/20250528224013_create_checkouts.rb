class CreateCheckouts < ActiveRecord::Migration[8.0]
  def change
    create_table :checkouts do |t|
      t.timestamps
    end
  end
end

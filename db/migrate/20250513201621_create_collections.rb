class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.string :division
      t.string :admin_group
      t.text :description
      t.string :division_page_url
      t.string :link_to_policies

      t.timestamps
    end
  end
end

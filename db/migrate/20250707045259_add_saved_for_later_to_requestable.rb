class AddSavedForLaterToRequestable < ActiveRecord::Migration[8.0]
  def change
    add_column :requestables, :saved_for_later, :boolean, default: false, null: false
  end
end

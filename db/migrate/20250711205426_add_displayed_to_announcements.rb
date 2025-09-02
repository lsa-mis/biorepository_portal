class AddDisplayedToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :displayed, :boolean, default: false, null: false
  end
end

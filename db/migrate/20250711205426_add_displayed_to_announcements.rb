class AddDisplayedToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :displayed, :boolean, default: true, null: false
  end
end

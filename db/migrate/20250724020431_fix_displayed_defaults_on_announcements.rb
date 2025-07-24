class FixDisplayedDefaultsOnAnnouncements < ActiveRecord::Migration[8.0]
  def change
    change_column_default :announcements, :displayed, from: nil, to: false
    change_column_null :announcements, :displayed, false
  end
end

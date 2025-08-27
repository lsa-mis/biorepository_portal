class RenameCountryInAddress < ActiveRecord::Migration[8.0]
  def change
   rename_column :addresses, :country, :country_code
  end
end

class SplitNameIntoFirstAndLast < ActiveRecord::Migration[7.0]
  def change
    add_column :addresses, :first_name, :string
    add_column :addresses, :last_name, :string
    remove_column :addresses, :name, :string
  end
end

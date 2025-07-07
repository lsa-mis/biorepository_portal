class AddDefaultToSavedForLaterOnRequestables < ActiveRecord::Migration[8.0]
  def change
    change_column_default :requestables, :saved_for_later, from: nil, to: false

    #Back‐fill any nulls and enforce NOT NULL
    Requestable.where(saved_for_later: nil).update_all(saved_for_later: false)
    change_column_null    :requestables, :saved_for_later, false
  end
end

# == Schema Information
#
# Table name: global_preferences
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  pref_type   :integer
#  value       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class GlobalPreference < ApplicationRecord
  enum :pref_type, [:boolean, :integer, :string, :image], prefix: true, scopes: true
  
  validates :name, uniqueness: true
  validates_presence_of :pref_type, :description

    def name=(value)
    super(value.try(:strip))
  end
end

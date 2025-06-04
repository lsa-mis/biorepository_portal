# == Schema Information
#
# Table name: app_preferences
#
#  id            :bigint           not null, primary key
#  description   :string
#  name          :string
#  pref_type     :integer
#  value         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :bigint           not null
#
# Indexes
#
#  index_app_preferences_on_collection_id  (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class AppPreference < ApplicationRecord
  belongs_to :collection

  enum :pref_type, [:boolean, :integer, :string], prefix: true, scopes: true
  validates_presence_of :name, :description, :pref_type
  validates :name, uniqueness: true
end

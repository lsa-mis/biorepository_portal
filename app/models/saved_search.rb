# == Schema Information
#
# Table name: saved_searches
#
#  id            :bigint           not null, primary key
#  filters       :jsonb
#  global        :boolean          default(FALSE), not null
#  name          :string           not null
#  search_params :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_saved_searches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class SavedSearch < ApplicationRecord
  belongs_to :user
  validates_presence_of :name, :search_params

  scope :global, -> { where(global: true) }

end

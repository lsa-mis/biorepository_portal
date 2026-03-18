# == Schema Information
#
# Table name: saved_searches
#
#  id            :bigint           not null, primary key
#  filters       :jsonb
#  global        :boolean          default(FALSE), not null
#  name          :string
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
require 'rails_helper'

RSpec.describe SavedSearch, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

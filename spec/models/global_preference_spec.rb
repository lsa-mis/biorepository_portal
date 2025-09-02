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
require 'rails_helper'

RSpec.describe GlobalPreference, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

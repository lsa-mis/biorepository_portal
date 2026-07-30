# == Schema Information
#
# Table name: map_fields
#
#  id            :bigint           not null, primary key
#  caption       :string
#  rails_field   :string
#  specify_field :string
#  table         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'rails_helper'

RSpec.describe MapField, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

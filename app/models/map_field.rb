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
class MapField < ApplicationRecord
end

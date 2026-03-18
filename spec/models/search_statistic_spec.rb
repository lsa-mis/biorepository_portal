# == Schema Information
#
# Table name: search_statistics
#
#  id          :bigint           not null, primary key
#  field_label :string           not null
#  field_name  :string           not null
#  field_value :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe SearchStatistic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

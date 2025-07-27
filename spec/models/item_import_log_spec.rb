# == Schema Information
#
# Table name: item_import_logs
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  note          :string
#  status        :string
#  user          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer
#
require 'rails_helper'

RSpec.describe ItemImportLog, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

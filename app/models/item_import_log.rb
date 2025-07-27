# == Schema Information
#
# Table name: item_import_logs
#
#  id            :bigint           not null, primary key
#  date          :datetime
#  note          :string           default([]), is an Array
#  status        :string
#  user          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer
#
class ItemImportLog < ApplicationRecord
end

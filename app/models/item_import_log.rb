# == Schema Information
#
# Table name: item_import_logs
#
#  id         :bigint           not null, primary key
#  date       :datetime
#  note       :string
#  status     :string
#  user       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ItemImportLog < ApplicationRecord
end

# == Schema Information
#
# Table name: search_statistics
#
#  id                :bigint           not null, primary key
#  field_label       :string           not null
#  field_name        :string           not null
#  field_value       :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  search_session_id :string
#
# Indexes
#
#  index_search_statistics_on_created_at                        (created_at)
#  index_search_statistics_on_search_session_id                 (search_session_id)
#  index_search_statistics_on_search_session_id_and_created_at  (search_session_id,created_at)
#
FactoryBot.define do
  factory :search_statistic do
    
  end
end

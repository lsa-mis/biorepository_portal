# == Schema Information
#
# Table name: loan_requests
#
#  id             :bigint           not null, primary key
#  checkout_items :string           default([]), is an Array
#  collection_ids :integer          default([]), is an Array
#  send_to        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_loan_requests_on_checkout_items  (checkout_items) USING gin
#  index_loan_requests_on_collection_ids  (collection_ids) USING gin
#  index_loan_requests_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class LoanRequest < ApplicationRecord
  belongs_to :user
  has_one_attached :pdf_file
  has_one_attached :csv_file
  has_many_attached :attachment_files

  validates :send_to, presence: true
end

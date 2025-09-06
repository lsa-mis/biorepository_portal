# == Schema Information
#
# Table name: checkouts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_checkouts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Checkout < ApplicationRecord
  has_many :requestables, dependent: :destroy
  has_many :preparations, through: :requestables
  has_many :unavalables, dependent: :destroy
  has_many :items, through: :unavalables

  belongs_to :user, optional: true

end

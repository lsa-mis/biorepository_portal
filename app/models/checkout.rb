# == Schema Information
#
# Table name: checkouts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Checkout < ApplicationRecord
  has_many :requestables, dependent: :destroy
  has_many :preparations, through: :requestables

end

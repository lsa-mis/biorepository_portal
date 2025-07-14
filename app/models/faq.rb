# == Schema Information
#
# Table name: faqs
#
#  id         :bigint           not null, primary key
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_faqs_on_position  (position)
#
class Faq < ApplicationRecord
  acts_as_list
  has_rich_text :question
  has_rich_text :answer

  # validates :question, presence: true, uniqueness: true
  # validates :answer, presence: true
end

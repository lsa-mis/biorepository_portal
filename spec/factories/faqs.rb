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
FactoryBot.define do
  factory :faq do
    
  end
end

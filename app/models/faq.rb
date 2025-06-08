# == Schema Information
#
# Table name: faqs
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Faq < ApplicationRecord
    has_rich_text :question
    has_rich_text :answer
end

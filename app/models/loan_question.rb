# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  question      :string
#  question_type :integer
#  required      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class LoanQuestion < ApplicationRecord
 has_many :options, dependent: :destroy
 accepts_nested_attributes_for :options, allow_destroy: true
 enum :question_type, [:text, :dropdown, :checkbox], prefix: true


 validates :question, presence: true, uniqueness: true
 validates :question_type, presence: true
 validate :must_have_multiple_options_if_needed

 private

 def must_have_multiple_options_if_needed
   if question_type.in?(%w[dropdown checkbox])
     option_count = options.reject(&:marked_for_destruction?).size
     if option_count < 2
       errors.add(:options, "must have at least two options for dropdown or checkbox question types")
     end
   end
 end
 end

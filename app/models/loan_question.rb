# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  question      :string
#  question_type :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class LoanQuestion < ApplicationRecord
  has_many :options, dependent: :destroy
  accepts_nested_attributes_for :options

  enum :question_type, [:string, :dropdown, :checkbox], prefix: true
  validates :question, presence: true
end

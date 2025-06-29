# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  position      :integer
#  question      :string
#  question_type :integer
#  required      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_loan_questions_on_position  (position)
#
class LoanQuestion < ApplicationRecord
  acts_as_list
  has_many :options, dependent: :destroy
  has_many :loan_answers, dependent: :destroy
  accepts_nested_attributes_for :options, allow_destroy: true
  enum :question_type, [:text, :dropdown, :checkbox, :attachment], prefix: true

  validates :question, presence: true, uniqueness: true
  validates :question_type, presence: true
end


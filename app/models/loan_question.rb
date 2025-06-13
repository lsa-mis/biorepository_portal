# == Schema Information
#
# Table name: loan_questions
#
#  id            :bigint           not null, primary key
#  question      :string
#  question_type :integer
#  required      :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class LoanQuestion < ApplicationRecord
  has_many :options, dependent: :destroy
  has_many :loan_answers, dependent: :destroy
  accepts_nested_attributes_for :options, allow_destroy: true
  has_one_attached :attachment
  enum :question_type, [:text, :dropdown, :checkbox, :attachment], prefix: true

  validates :question, presence: true, uniqueness: true
  validates :question_type, presence: true
  validates :attachment, presence: true, if: -> { question_type_attachment? }
end


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
require 'rails_helper'

RSpec.describe LoanQuestion, type: :model do
 it "is valid with a unique question and question_type" do
   question = build(:loan_question)
   expect(question).to be_valid
 end


 it "is invalid without a question" do
   question = build(:loan_question, question: nil)
   expect(question).not_to be_valid
   expect(question.errors[:question]).to include("can't be blank")
 end


 it "is invalid without a question_type" do
   question = build(:loan_question, question_type: nil)
   expect(question).not_to be_valid
   expect(question.errors[:question_type]).to include("can't be blank")
 end


 it "is invalid with duplicate question" do
   create(:loan_question, question: "Duplicate")
   duplicate = build(:loan_question, question: "Duplicate")
   expect(duplicate).not_to be_valid
   expect(duplicate.errors[:question]).to include("has already been taken")
 end


 it "is valid with at least 2 options for dropdown" do
   question = build(:loan_question, :with_dropdown_options)
   expect(question).to be_valid
 end


 it "is valid with at least 2 options for checkbox type" do
   question = build(:loan_question, :with_checkbox_options)
   expect(question).to be_valid
 end


 it "is invalid with fewer than 2 options for dropdown" do
   question = build(:loan_question, question_type: :dropdown)
   question.options << build(:option)
   expect(question).not_to be_valid
   expect(question.errors[:options]).to include("must have at least two options for dropdown or checkbox question types")
 end


 it "is invalid with fewer than 2 options for checkbox" do
   question = build(:loan_question, question_type: :checkbox)
   question.options << build(:option)
   expect(question).not_to be_valid
   expect(question.errors[:options]).to include("must have at least two options for dropdown or checkbox question types")
 end
end

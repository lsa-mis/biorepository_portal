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
FactoryBot.define do
 factory :loan_question do
   question { "How did you hear about us?" }
   question_type { :text }


   trait :with_dropdown_options do
     question_type { :dropdown }
     after(:build) do |loan_question|
       loan_question.options << build(:option, loan_question: loan_question)
       loan_question.options << build(:option, loan_question: loan_question)
     end
   end


   trait :with_checkbox_options do
     question_type { :checkbox }
     after(:build) do |loan_question|
       loan_question.options << build(:option, loan_question: loan_question)
       loan_question.options << build(:option, loan_question: loan_question)
     end
   end
 end
end

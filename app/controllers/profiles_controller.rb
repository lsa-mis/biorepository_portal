class ProfilesController < ApplicationController

  def show
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path(current_user), notice: "Profile updated successfully."
    else
      flash.now[:alert] = "Failed to update profile."
      render :edit, status: :unprocessable_entity
    end
  end

  def loan_questions
    @loan_questions = LoanQuestion.all
    @loan_answers = current_user.loan_answers.includes(:loan_question)
  end

  def update_loan_questions
    @loan_questions = LoanQuestion.all
    @loan_questions.each do |question|
      answer = question.loan_answers.find_or_initialize_by(user: current_user)
      answer.answer = params[:loan_answers][question.id.to_s]
      answer.save
    end
    redirect_to profile_path, notice: "Loan questions updated successfully."
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :affiliation, :orcid)
  end
  
end

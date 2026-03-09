# app/controllers/saved_searches_controller.rb
class SavedSearchesController < ApplicationController
  before_action :set_saved_search, only: [:edit, :update, :destroy]

  def index
    @global_saved_searches = SavedSearch.global
    @saved_searches = current_user.saved_searches.where(global: false)
  end

  def edit
  end

  def update
    if @saved_search.update(saved_search_params)
      redirect_to saved_searches_path, notice: 'Saved search was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @saved_search.destroy
    redirect_to saved_searches_path, notice: 'Saved search was successfully deleted.'
  end
  
  private

  def set_saved_search
    @saved_search = current_user.saved_searches.find(params[:id])
  end

  def saved_search_params
    params.require(:saved_search).permit(:name, :global)
  end
end

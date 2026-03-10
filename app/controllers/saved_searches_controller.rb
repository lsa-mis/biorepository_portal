# app/controllers/saved_searches_controller.rb
class SavedSearchesController < ApplicationController
  before_action :set_saved_search, only: [:edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    @global_saved_searches = SavedSearch.global
    if current_user
      @saved_searches = current_user.saved_searches.where(global: false)
    else
      @saved_searches = []
    end
    authorize SavedSearch
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
    @saved_search = SavedSearch.find(params[:id])
    authorize @saved_search
  end

  def saved_search_params
    params.require(:saved_search).permit(:name, :global)
  end
end

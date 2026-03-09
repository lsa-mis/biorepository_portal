# app/controllers/saved_searches_controller.rb
class SavedSearchesController < ApplicationController
  before_action :set_saved_search, only: [:show, :edit, :update, :destroy]

  def index
    @global_saved_searches = SavedSearch.global
    @saved_searches = current_user.saved_searches
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

  def show

    # Apply the saved search parameters to your search logic
    # @results = Item.search_by(@saved_search.search_params) # Example of re-running the search
    # render 'items/search_results' # Display results using the regular search results view
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

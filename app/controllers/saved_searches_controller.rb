# app/controllers/saved_searches_controller.rb
class SavedSearchesController < ApplicationController

  def create
    fail
    @saved_search = current_user.saved_searches.new(saved_search_params)
    @saved_search.search_params = params[:search] # Capture the search parameters

    if @saved_search.save
      redirect_to search_results_path, notice: "Search saved successfully!"
    else
      # Handle errors (maybe render the search page again with an alert)
    end
  end

  def show
    @saved_search = current_user.saved_searches.find(params[:id])
    # Apply the saved search parameters to your search logic
    @results = Item.search_by(@saved_search.search_params) # Example of re-running the search
    render 'items/search_results' # Display results using the regular search results view
  end
  
  # ... other actions like index, destroy

  private

  def saved_search_params
    params.require(:saved_search).permit(:name)
  end
end

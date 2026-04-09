# app/controllers/saved_searches_controller.rb
class SavedSearchesController < ApplicationController
  before_action :set_saved_search, only: [:edit, :update, :destroy, :move_up, :move_down]
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    @global_saved_searches = SavedSearch.global.order(:position)
    if current_user
      @saved_searches = current_user.saved_searches.where(global: false).order(created_at: :desc) 
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

  def move_up
    move_saved_search(:higher, "moved up")
  end

  def move_down
    move_saved_search(:lower, "moved down")
  end
  
  private

  def move_saved_search(direction, notice_suffix)
    case direction
    when :higher
      @saved_search.move_higher
    when :lower
      @saved_search.move_lower
    end

    if @saved_search.global
      turbo_frame = "global_saved_searches_list"
      @saved_searches = SavedSearch.global.order(:position)
    else      
      turbo_frame = "saved_searches_list"
      @saved_searches = current_user.saved_searches.where(global: false).order(created_at: :desc)
    end

    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update(turbo_frame, 
          partial: "saved_searches/list_of_saved_searches", 
          locals: { type: @saved_search.global ? :global : :personal, saved_searches: @saved_searches }
        )
      }
      format.html { redirect_to saved_searches_path, notice: "Saved search #{notice_suffix}." }
    end
  end

  def set_saved_search
    @saved_search = SavedSearch.find(params[:id])
    authorize @saved_search
  end

  def saved_search_params
    permitted_attributes = [:name]
    permitted_attributes << :global if current_user && is_admin?
    params.require(:saved_search).permit(*permitted_attributes)
  end
end

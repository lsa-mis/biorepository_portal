class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: [:edit, :update]
  def index
    authorize Announcement
    @announcements = Announcement.order(:location)
  end

  def edit
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to announcements_path, notice: "Announcement updated"
    else
      render :edit
    end
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
    authorize @announcement
  end

  def announcement_params
    params.require(:announcement).permit(:content, :displayed)
  end
end

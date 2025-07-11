class AnnouncementsController < ApplicationController
  def index
    authorize Announcement
    @announcements = Announcement.order(:location)
  end

  def edit
    @announcement = Announcement.find(params[:id])
    authorize @announcement
  end

  def update
    @announcement = Announcement.find(params[:id])
    authorize @announcement
    if @announcement.update(announcement_params)
      redirect_to announcements_path, notice: "Announcement updated"
    else
      render :edit
    end
  end

  private

  def announcement_params
    params.require(:announcement).permit(:content, :displayed)
  end
end

module Pinhole
  class AlbumsController < ApplicationController
    def index
      @albums = library.albums
    end

    def show
      @album = library.album(params[:id]) or raise ActionController::RoutingError, "No album #{params[:id]}"
      @photos = @album.photos
    end

    def create
      name = params[:name].to_s.strip.first(60)
      if name.blank?
        redirect_back fallback_location: albums_path, alert: "Give the album a name."
      else
        album = library.create_album(name, chosen_ids)
        redirect_to album_path(album), notice: "Made “#{album.name}”."
      end
    end

    def destroy
      album = library.album(params[:id]) or raise ActionController::RoutingError, "No album #{params[:id]}"
      library.delete_album(album.id)
      redirect_to albums_path, notice: "Deleted “#{album.name}”. Its photos are still in your library."
    end

    private

    def chosen_ids = Array(params[:ids]).map(&:to_s).select { |id| Photo.find(id) }
  end
end

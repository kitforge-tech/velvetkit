module Pinhole
  # The star in the photo viewer. It answers with a Turbo Stream, so the viewer
  # stays open and only the star, and the one on the photo's tile, change.
  class FavouritesController < ApplicationController
    def update
      @photo = Photo.find!(params[:id])
      library.favourite?(@photo) ? library.unfavourite([ @photo.id ]) : library.favourite([ @photo.id ])

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path }
      end
    end
  end
end

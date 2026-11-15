module Pinhole
  class PhotosController < ApplicationController
    def index
      @photos = library.photos
    end

    def favourites
      @photos = library.favourites
    end

    def archive
      @photos = library.archive
    end

    def bin
      @photos = library.bin
    end

    def search
      @query = params[:q].to_s.strip.first(80)
      @photos = @query.present? ? library.search(@query) : []
    end
  end
end

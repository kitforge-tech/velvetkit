module Pinhole
  class PlacesController < ApplicationController
    def index
      @places = library.places
    end

    def show
      @place = Photo::PLACES[params[:id]] or raise ActionController::RoutingError, "No place #{params[:id]}"
      @photos = library.at(@place)
    end
  end
end

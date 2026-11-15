module Pinhole
  # The selection bar's buttons: each posts the photos chosen, and what to do
  # with them, then comes back to the page, which Turbo morphs in place.
  class SelectionsController < ApplicationController
    ACTIONS = {
      "favourite" => "Added %{count} to favourites.",
      "unfavourite" => "Removed %{count} from favourites.",
      "archive" => "Archived %{count}.",
      "unarchive" => "Moved %{count} back to your photos.",
      "bin" => "Moved %{count} to the bin.",
      "restore" => "Restored %{count}.",
      "delete" => "Deleted %{count} for good.",
      "add_to_album" => "Added %{count} to “%{album}”.",
      "remove_from_album" => "Removed %{count} from “%{album}”.",
      "empty_bin" => "Emptied the bin."
    }.freeze

    def create
      action = params[:do].to_s
      return head(:unprocessable_entity) unless ACTIONS.key?(action)

      ids = chosen_ids
      album = library.album(params[:album].to_s)
      return redirect_back(fallback_location: root_path, alert: "Choose some photos first.") if ids.empty? && action != "empty_bin"
      return head(:unprocessable_entity) if action.end_with?("album") && album.nil?

      case action
      when "favourite" then library.favourite(ids)
      when "unfavourite" then library.unfavourite(ids)
      when "archive" then library.archive!(ids)
      when "unarchive" then library.unarchive(ids)
      when "bin" then library.bin!(ids)
      when "restore" then library.restore(ids)
      when "delete" then library.delete(ids)
      when "empty_bin" then library.empty_bin
      when "add_to_album" then library.add_to_album(album.id, ids)
      when "remove_from_album" then library.remove_from_album(album.id, ids)
      end

      count = ids.size == 1 ? "1 photo" : "#{ids.size} photos"
      redirect_back fallback_location: root_path, notice: format(ACTIONS[action], count:, album: album&.name)
    end

    private

    def chosen_ids = Array(params[:ids]).map(&:to_s).uniq.select { |id| Photo.find(id) }
  end
end

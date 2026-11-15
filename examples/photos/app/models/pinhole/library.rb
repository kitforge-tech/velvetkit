module Pinhole
  # One visitor's library: what they've favourited, archived, put in the bin
  # or deleted, and their albums. Kept in their session, so each visitor gets
  # the same starting library and their changes are theirs alone.
  class Library
    STORAGE_TOTAL_GB = 100
    STORAGE_USED_GB = 61.4

    def initialize(session)
      @state = session[:pinhole] ||= {}
    end

    def photos = visible(Photo.all)
    def favourites = photos.select { |photo| favourite?(photo) }
    def archive = Photo.all.select { |photo| in?("archived", photo) && !gone?(photo) }
    def bin = Photo.all.select { |photo| in?("binned", photo) && !in?("deleted", photo) }
    def search(query) = photos.select { |photo| photo.matches?(query) }
    def at(place) = photos.select { |photo| photo.place == place }

    def favourite?(photo) = favourite_ids.include?(photo.id)
    def archived?(photo) = in?("archived", photo)
    def binned?(photo) = in?("binned", photo)

    def places
      photos.group_by(&:place).map { |place, photos| { place:, count: photos.size, cover: photos.first } }
    end

    def albums
      ids = @state["albums"] || Album::STARTING.to_h { |album| [ album.id, album.photo_ids ] }
      names = Album::STARTING.to_h { |album| [ album.id, album.name ] }.merge(@state["album_names"] || {})
      ids.map { |id, photo_ids| Album.new(id:, name: names.fetch(id, id), photo_ids: photo_ids.select { |pid| visible_id?(pid) }) }
    end

    def album(id) = albums.find { |album| album.id == id }

    # What the selection bar's buttons do, to each photo chosen.
    def favourite(ids) = write("favourites", favourite_ids | ids)
    def unfavourite(ids) = write("favourites", favourite_ids - ids)
    def archive!(ids) = write("archived", list("archived") | ids)
    def unarchive(ids) = write("archived", list("archived") - ids)
    def bin!(ids) = write("binned", list("binned") | ids)
    def restore(ids) = write("binned", list("binned") - ids)
    def delete(ids) = write("deleted", list("deleted") | (ids & list("binned")))
    def empty_bin = write("deleted", list("deleted") | list("binned"))

    def add_to_album(album_id, ids)
      change_albums { |albums| albums[album_id] = (albums.fetch(album_id, []) | ids) if albums.key?(album_id) }
    end

    def remove_from_album(album_id, ids)
      change_albums { |albums| albums[album_id] = albums.fetch(album_id, []) - ids if albums.key?(album_id) }
    end

    def create_album(name, ids = [])
      id = "#{name.parameterize.presence || 'album'}-#{SecureRandom.hex(2)}"
      @state["album_names"] = (@state["album_names"] || {}).merge(id => name.strip)
      change_albums { |albums| albums[id] = ids }
      album(id)
    end

    def delete_album(id)
      change_albums { |albums| albums.delete(id) }
    end

    def storage_share = (STORAGE_USED_GB / STORAGE_TOTAL_GB * 100).round

    private

    # A photo starts out a favourite if it's one of these, until the visitor
    # changes their favourites.
    STARTING_FAVOURITES = %w[cat-2 sunset-1 mountain-1 garden-0 dog-1 lighthouse-1].freeze

    def favourite_ids = @state["favourites"] || STARTING_FAVOURITES
    def list(key) = @state[key] || []
    def in?(key, photo) = list(key).include?(photo.id)
    def gone?(photo) = in?("binned", photo) || in?("deleted", photo)
    def visible_id?(id) = !(list("archived") | list("binned") | list("deleted")).include?(id)
    def visible(photos) = photos.select { |photo| visible_id?(photo.id) }

    def write(key, ids)
      @state[key] = ids.select { |id| Photo.find(id) }
    end

    def change_albums
      albums = (@state["albums"] || Album::STARTING.to_h { |album| [ album.id, album.photo_ids ] }).transform_values(&:dup)
      yield albums
      @state["albums"] = albums.transform_values { |ids| ids.select { |id| Photo.find(id) } }
    end
  end
end

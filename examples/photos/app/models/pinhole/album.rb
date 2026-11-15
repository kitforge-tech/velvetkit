module Pinhole
  # An album: a name and the photos in it. The starting albums are here; the
  # ones a visitor makes, and what they add or take out, are kept in their
  # session by Library.
  Album = Data.define(:id, :name, :photo_ids) do
    def photos = photo_ids.filter_map { |id| Photo.find(id) }.sort_by(&:taken_at).reverse
    def cover = photos.first
    def to_param = id
  end

  class Album
    STARTING = [
      [ "coast-walks", "Coast walks", %w[coast-0 coast-2 boat-0 boat-2 lighthouse-0 lighthouse-1 lighthouse-2 sunset-1] ],
      [ "mountains", "Mountains", %w[mountain-0 mountain-1 mountain-2 snow-0 snow-1 snow-2 waterfall-0 waterfall-1 waterfall-2] ],
      [ "garden", "The garden", %w[garden-0 garden-1 garden-2 flowers-0 flowers-1 birds-0 birds-1] ],
      [ "autumn", "Autumn colours", %w[leaves-0 leaves-1 leaves-2 forest-0 forest-1 forest-2] ],
      [ "kitchen", "Kitchen", %w[coffee-0 coffee-1 coffee-2 fruit-1 fruit-2] ],
      [ "pets", "Pets", %w[cat-1 cat-2 dog-1] ]
    ].map { |id, name, photo_ids| new(id:, name:, photo_ids:) }.freeze

    # The starting albums a photo is in, for search; what a visitor changed
    # only shows on their own pages.
    def self.containing(photo) = STARTING.select { |album| album.photo_ids.include?(photo.id) }
  end
end

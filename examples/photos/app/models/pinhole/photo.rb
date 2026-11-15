module Pinhole
  # A photo in the library. There's no database: the photos are listed here,
  # with made-up dates and places, and the files are in app/assets/images.
  Photo = Data.define(:id, :title, :taken_at, :place, :width, :height, :tags) do
    def small_path = "pinhole/small/#{id}.webp"
    def large_path = "pinhole/large/#{id}.webp"
    def ratio = width.to_f / height
    def portrait? = height > width
    def taken_on = taken_at.to_date
    def megapixels = (width * height / 1_000_000.0).round(1)

    # Settings a camera would note, made up but steady for each photo.
    def exposure
      seed = id.sum
      [ "f/#{%w[1.8 2.2 2.8 4 5.6 8][seed % 6]}", "1/#{[ 60, 125, 250, 500, 1000 ][seed % 5]} s",
        "ISO #{[ 50, 100, 200, 400, 800 ][seed % 5]}", "#{[ 24, 26, 35, 50, 77 ][seed % 5]} mm" ].join(" · ")
    end

    def file_size = "#{((width * height * 0.32) / 1_000_000.0).round(1)} MB"

    def matches?(query)
      # "roses" finds a rose: plurals are cut back to the word.
      words = query.to_s.downcase.split.map { |word| word.length > 3 ? word.delete_suffix("s") : word }
      haystack = [ title, place.name, *tags, *Album.containing(self).map(&:name) ].join(" ").downcase
      words.any? && words.all? { |word| haystack.include?(word) }
    end
  end

  class Photo
    Place = Data.define(:slug, :name, :region)

    PLACES = {
      "saltmarsh-bay" => Place.new("saltmarsh-bay", "Saltmarsh Bay", "North coast"),
      "kestrel-peaks" => Place.new("kestrel-peaks", "Kestrel Peaks", "High country"),
      "fernhill" => Place.new("fernhill", "Fernhill", "Garden and woods"),
      "home" => Place.new("home", "Home", "Kitchen and sofa"),
      "old-town" => Place.new("old-town", "Old Town", "River and bridges"),
      "dune-sea" => Place.new("dune-sea", "Dune Sea", "Desert")
    }.freeze

    # id, width, height, title, taken at, place, tags. The dates are made up
    # around Pinhole's "today", 14 November 2026.
    ROWS = [
      [ "cat-2", 1920, 1080, "Curled up on the sofa", "2026-11-14 08:12", "home", %w[cat pets] ],
      [ "coffee-1", 1920, 2880, "Flat white on the table", "2026-11-14 09:40", "home", %w[coffee food] ],
      [ "leaves-2", 1920, 1280, "Leaves on the lawn", "2026-11-13 15:02", "fernhill", %w[autumn leaves] ],
      [ "leaves-1", 1920, 1280, "Leaf litter", "2026-11-13 15:10", "fernhill", %w[autumn leaves] ],
      [ "forest-2", 1920, 2880, "Autumn woods", "2026-11-13 15:44", "fernhill", %w[autumn forest trees] ],
      [ "coffee-0", 1920, 1282, "Espresso pouring", "2026-11-10 07:55", "home", %w[coffee food] ],
      [ "fruit-1", 1920, 1291, "Berries for breakfast", "2026-11-10 08:20", "home", %w[fruit food breakfast] ],
      [ "forest-0", 1920, 1280, "Edge of the birch wood", "2026-11-02 11:30", "fernhill", %w[autumn forest trees] ],
      [ "forest-1", 1920, 2880, "Forest in the fog", "2026-11-02 12:05", "fernhill", %w[forest fog trees] ],
      [ "leaves-0", 1920, 2880, "Leaves on the water", "2026-11-02 12:40", "fernhill", %w[autumn leaves water] ],
      [ "sunset-0", 1920, 1078, "Purple sky over the city", "2026-10-18 18:41", "old-town", %w[sunset sky city] ],
      [ "bridge-0", 1920, 1080, "Bridge lit up at night", "2026-10-18 19:20", "old-town", %w[bridge night city river] ],
      [ "bridge-2", 1920, 1280, "Road bridge over the river", "2026-10-17 10:15", "old-town", %w[bridge river] ],
      [ "sunset-1", 1920, 1280, "Sunset over the sea", "2026-09-07 19:32", "saltmarsh-bay", %w[sunset sea sky] ],
      [ "boat-2", 1920, 1440, "Harbour at dusk", "2026-09-07 18:50", "saltmarsh-bay", %w[harbour boats sea] ],
      [ "lighthouse-2", 1920, 1278, "Harbour light", "2026-09-07 14:10", "saltmarsh-bay", %w[lighthouse sea] ],
      [ "lighthouse-1", 1920, 1280, "Looking up at the lighthouse", "2026-09-06 16:25", "saltmarsh-bay", %w[lighthouse] ],
      [ "lighthouse-0", 1920, 1440, "Lighthouse by the fields", "2026-09-06 15:58", "saltmarsh-bay", %w[lighthouse fields] ],
      [ "coast-2", 1920, 1426, "Grass running down to the rocks", "2026-09-06 11:20", "saltmarsh-bay", %w[coast sea cliffs] ],
      [ "coast-0", 1920, 1167, "Cliffs at sunrise", "2026-09-06 06:48", "saltmarsh-bay", %w[coast sunrise cliffs] ],
      [ "boat-0", 1920, 1441, "Beach below the village", "2026-09-05 17:30", "saltmarsh-bay", %w[beach sea] ],
      [ "dog-1", 1920, 1280, "Waiting for the ball", "2026-08-22 17:05", "home", %w[dog pets] ],
      [ "fruit-2", 1920, 1280, "Fruit platter", "2026-08-16 12:30", "home", %w[fruit food] ],
      [ "waterfall-1", 1920, 1100, "Waterfall into the gorge", "2026-07-15 13:40", "kestrel-peaks", %w[waterfall mountains] ],
      [ "waterfall-2", 1920, 1240, "Stream over the rocks", "2026-07-15 12:10", "kestrel-peaks", %w[stream water] ],
      [ "waterfall-0", 1920, 2560, "Mossy falls", "2026-07-14 15:22", "kestrel-peaks", %w[waterfall moss] ],
      [ "mountain-2", 1920, 1080, "Boardwalk by the lake", "2026-07-13 10:05", "kestrel-peaks", %w[lake mountains] ],
      [ "mountain-1", 1920, 1280, "Peak reflected in the lake", "2026-07-12 19:15", "kestrel-peaks", %w[lake mountains reflection] ],
      [ "mountain-0", 1920, 1277, "Trail into the hills", "2026-07-12 09:30", "kestrel-peaks", %w[trail mountains] ],
      [ "birds-0", 1920, 1280, "Sparrow on a branch", "2026-06-21 07:45", "fernhill", %w[bird garden] ],
      [ "garden-2", 1500, 1000, "Rose beds in bloom", "2026-06-20 16:30", "fernhill", %w[roses garden flowers] ],
      [ "garden-1", 1500, 1000, "Rose garden", "2026-06-20 16:12", "fernhill", %w[roses garden flowers] ],
      [ "garden-0", 1920, 2560, "Pink rose", "2026-06-20 15:50", "fernhill", %w[rose garden flowers] ],
      [ "birds-1", 1920, 1285, "Bird in the palms", "2026-05-09 10:20", "fernhill", %w[bird garden] ],
      [ "flowers-1", 1920, 3059, "Pasque flower up close", "2026-05-03 14:00", "fernhill", %w[flowers garden] ],
      [ "flowers-0", 1920, 1275, "Poppies against the sky", "2026-05-03 13:35", "fernhill", %w[poppies flowers] ],
      [ "snow-2", 1920, 1080, "Storm over the glacier", "2026-02-14 15:10", "kestrel-peaks", %w[snow mountains winter] ],
      [ "snow-1", 1920, 1272, "Snowy peaks", "2026-02-14 11:45", "kestrel-peaks", %w[snow mountains winter] ],
      [ "snow-0", 1920, 1440, "Fresh snow on the ridge", "2026-02-13 09:20", "kestrel-peaks", %w[snow mountains winter] ],
      [ "coffee-2", 1920, 1280, "Black coffee and beans", "2025-12-24 08:30", "home", %w[coffee food] ],
      [ "cat-1", 1920, 1280, "Cat asleep in the sun", "2025-12-20 13:15", "home", %w[cat pets] ],
      [ "sunset-2", 1920, 1456, "Thunderhead at sunset", "2025-11-16 17:52", "dune-sea", %w[sunset clouds desert] ],
      [ "desert-2", 1920, 1280, "Dunes under big clouds", "2025-11-15 12:30", "dune-sea", %w[desert dunes] ],
      [ "desert-1", 1920, 1080, "Dunes at dawn", "2025-11-15 06:40", "dune-sea", %w[desert dunes sunrise] ],
      [ "desert-0", 1920, 1285, "Ripples across the dunes", "2025-11-14 16:05", "dune-sea", %w[desert dunes] ]
    ].freeze

    ALL = ROWS.map do |id, width, height, title, taken_at, place, tags|
      Pinhole::Photo.new(id:, width:, height:, title:, taken_at: Time.zone.parse(taken_at), place: PLACES.fetch(place), tags:)
    end.sort_by(&:taken_at).reverse.freeze

    INDEX = ALL.index_by(&:id).freeze

    def self.all = ALL
    def self.find(id) = INDEX[id]
    def self.find!(id) = INDEX.fetch(id) { raise ActionController::RoutingError, "No photo #{id}" }
  end
end

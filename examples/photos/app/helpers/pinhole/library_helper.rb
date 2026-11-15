module Pinhole
  module LibraryHelper
    # Pinhole's "today", so the dates read the same whenever the example is
    # opened.
    TODAY = Date.new(2026, 11, 14)

    def nav_items
      [
        { text: "Photos", icon: "image", href: root_path },
        { text: "Favourites", icon: "star", href: favourites_path },
        { text: "Albums", icon: "book-image", href: albums_path, albums: true },
        { text: "Places", icon: "map-pin", href: places_path },
        { text: "Archive", icon: "archive", href: archive_path },
        { text: "Bin", icon: "trash-2", href: bin_path }
      ]
    end

    def nav_active?(href)
      return current_page?(href) if href == root_path

      request.path.start_with?(href)
    end

    # Photos by the day they were taken, newest first.
    def days(photos) = photos.group_by(&:taken_on).sort_by { |date, _| date }.reverse

    def day_label(date)
      return "Today" if date == TODAY
      return "Yesterday" if date == TODAY - 1
      return date.strftime("%A") if date > TODAY - 7

      date.year == TODAY.year ? date.strftime("%a, %-d %b") : date.strftime("%a, %-d %b %Y")
    end

    def day_id(date) = "day-#{date.iso8601}"

    # A mark on the scrubber for each month, at its first day, with the year
    # written at the newest month of each year.
    def month_marks(days)
      seen_years = Set.new
      days.map(&:first).group_by(&:beginning_of_month).map do |month, dates|
        major = month.year.to_s if seen_years.add?(month.year)
        { href: "##{day_id(dates.first)}", label: month.strftime("%B %Y"), major: }
      end
    end

    # Each tile grows with its photo's shape, so a row of them ends up one
    # height and fills the width, whatever the mix of wide and tall photos.
    def tile_style(photo) = "flex: #{photo.ratio.round(3)} 1 calc(var(--row) * #{photo.ratio.round(3)})"

    def photo_count(count) = count == 1 ? "1 photo" : "#{count} photos"

    def date_range(photos)
      return if photos.empty?

      first, last = photos.map(&:taken_on).minmax
      return first.strftime("%-d %B %Y") if first == last
      return "#{first.strftime('%-d')}–#{last.strftime('%-d %B %Y')}" if first.month == last.month && first.year == last.year

      "#{first.strftime('%b %Y')} – #{last.strftime('%b %Y')}"
    end

    # The highlights at the top of the library.
    def memories
      [
        { title: "One year ago", detail: "Dune Sea, Nov 2025", href: place_path("dune-sea"), photo: Photo.find("desert-1") },
        { title: "Coast walks", detail: "Saltmarsh Bay", href: album_path("coast-walks"), photo: Photo.find("sunset-1") },
        { title: "Autumn colours", detail: "This month", href: album_path("autumn"), photo: Photo.find("forest-2") },
        { title: "Summer in the hills", detail: "July 2026", href: album_path("mountains"), photo: Photo.find("mountain-1") },
        { title: "Roses at Fernhill", detail: "June 2026", href: place_path("fernhill"), photo: Photo.find("garden-1") },
        { title: "Pets", detail: "3 photos", href: album_path("pets"), photo: Photo.find("cat-2") }
      ].select { |memory| library.photos.include?(memory[:photo]) }
    end

    def storage_text = "#{Library::STORAGE_USED_GB} GB of #{Library::STORAGE_TOTAL_GB} GB used"
  end
end

# Pinhole

An example photo library built with VelvetKit: highlights that scroll
sideways, photos grouped by day in rows that fill the width, a date scrubber,
choosing photos to favourite, archive, bin or put in albums, and a viewer with
zoom and an info panel. It runs inside the docs site at
[/examples/photos](https://velvetkit.com/examples/photos), but its code lives
here, apart from the docs.

It's a Rails engine, `Pinhole`, mounted by `site/config/routes.rb`. It has no
database: the photos are listed in `app/models/pinhole/photo.rb`, and what a
visitor changes (favourites, the archive, the bin, albums) is kept in their
session by `app/models/pinhole/library.rb`, so everyone starts from the same
library.

## Running it

Start the docs site and open <http://localhost:3000/examples/photos>:

    cd site && bin/dev

## What's where

- **Components:** it uses the site's copy of the kit (`UI::`). The sidebar,
  the highlights (`Carousel`), the viewer (`Gallery` with `strip: false`), the
  bar of what to do with the chosen photos (`SelectionBar`) and the date rail
  (`Scrubber`) are all kit components; the photo grid is a few lines of CSS in
  `app/views/pinhole/shared/_library.html.erb`.
- **Theme:** `app/assets/stylesheets/pinhole/theme.css`. The site builds the
  library's own stylesheet from `site/app/assets/stylesheets/pinhole.tailwind.css`.
- **JavaScript:** `app/assets/javascripts/pinhole/library.js` makes a click
  on a photo choose it while others are chosen, and closes the viewer before a
  button in it changes the page. Everything else is the kit's.
- **Changes in place:** each button posts and comes back to the same page,
  which Turbo morphs, keeping the scroll (`turbo-refresh-method` in the
  layout). The star in the viewer answers with a Turbo Stream instead, so the
  viewer stays open.
- **Photos:** CC0, from Wikimedia Commons; see [PHOTOS.md](PHOTOS.md).

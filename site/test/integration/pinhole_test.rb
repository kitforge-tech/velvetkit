require "test_helper"

# Pinhole, the example photo library mounted at /examples/photos.
class PinholeTest < ActionDispatch::IntegrationTest
  test "the library shows memories, the photos by day, the scrubber and the viewer" do
    get "/examples/photos"
    assert_response :success
    assert_select "title", /\APhotos · Pinhole/
    assert_select "aside#pinhole-sidebar a[aria-current=page][data-shape=pill]", text: "Photos"
    assert_select "[data-slot=carousel][aria-label=Memories] li", minimum: 4
    assert_select "section h2#day-2026-11-14", /Today/
    assert_select "section h2#day-2026-11-13", /Yesterday/
    assert_select "[data-selection=item][name='ids[]'][form=selection]", Pinhole::Photo.all.size
    assert_select "[data-ui--gallery-target=trigger]", Pinhole::Photo.all.size
    assert_select "nav[data-slot=scrubber] a[href='#day-2026-11-14']", text: "2026"
    assert_select "[data-slot=selection-bar] button[value=archive]"
    assert_select "dialog aside [data-ui--gallery-target=perImage]", Pinhole::Photo.all.size
    # Each day can be chosen at once, from the box by its heading.
    assert_select "section[data-selection-group] [data-selection=all][aria-label='Select all photos from Today']"
    assert_select "dialog#ui-confirm-dialog"
  end

  test "pages below another say where they are, and deleting asks with the kit's dialog" do
    get "/examples/photos/albums/coast-walks"
    assert_select "nav[aria-label] a[href='/examples/photos/albums']", text: "Albums"
    assert_select "nav[aria-label] [aria-current=page]", text: "Coast walks"
    assert_select "form[data-turbo-confirm][data-confirm-variant=destructive] button", /Delete album/

    get "/examples/photos/places/fernhill"
    assert_select "nav[aria-label] a[href='/examples/photos/places']", text: "Places"

    post "/examples/photos/selection", params: { do: "bin", ids: %w[cat-2] }
    get "/examples/photos/bin"
    assert_select "button[value=delete][data-turbo-confirm][data-confirm-button='Delete forever']"
  end

  test "chosen photos are archived, binned, restored and deleted, for this visitor only" do
    post "/examples/photos/selection", params: { do: "archive", ids: %w[cat-2 coffee-1] }
    assert_redirected_to "/examples/photos/"
    follow_redirect!
    assert_match "Archived 2 photos.", response.body
    assert_select "[data-selection=item]", Pinhole::Photo.all.size - 2

    get "/examples/photos/archive"
    assert_select "[data-selection=item]", 2
    assert_select "[data-slot=selection-bar] button[value=unarchive]"

    post "/examples/photos/selection", params: { do: "bin", ids: %w[desert-0] }
    get "/examples/photos/bin"
    assert_select "[data-selection=item][value=desert-0]"
    post "/examples/photos/selection", params: { do: "delete", ids: %w[desert-0] }
    get "/examples/photos/bin"
    assert_select "h2", text: "The bin is empty"

    open_session do |other|
      other.get "/examples/photos"
      other.assert_select "[data-selection=item]", Pinhole::Photo.all.size
    end
  end

  test "favourites toggle from the viewer with a stream, and albums take photos" do
    patch "/examples/photos/photos/desert-1/favourite", headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_match %(target="fav-desert-1"), response.body
    assert_match %(target="tile-star-desert-1"), response.body
    get "/examples/photos/favourites"
    assert_select "[data-selection=item][value=desert-1]"

    post "/examples/photos/selection", params: { do: "add_to_album", album: "pets", ids: %w[birds-0] }
    get "/examples/photos/albums/pets"
    assert_select "[data-selection=item][value=birds-0]"
    assert_select "aside#pinhole-sidebar a[aria-current=page]", text: "Pets"

    post "/examples/photos/albums", params: { name: "Weekend away" }
    follow_redirect!
    assert_select "h1", "Weekend away"
    assert_select "h2", text: "This album is empty"
  end

  test "search, places, and what isn't there" do
    get "/examples/photos/search", params: { q: "roses" }
    assert_select "[data-selection=item]", 3
    assert_select "meta[name=robots][content='noindex, follow']"
    get "/examples/photos/search", params: { q: "zebra" }
    assert_select "h2", text: /No photos match/

    get "/examples/photos/places/kestrel-peaks"
    assert_select "h1", "Kestrel Peaks"
    get "/examples/photos/places/nowhere"
    assert_response :not_found
    get "/examples/photos/albums/nope"
    assert_response :not_found
    post "/examples/photos/selection", params: { do: "launch", ids: %w[cat-2] }
    assert_response :unprocessable_entity
  end
end

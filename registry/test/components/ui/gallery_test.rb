# frozen_string_literal: true

require "test_helper"

class UI::GalleryTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_gallery(count: 3, **opts)
    render_inline(UI::Gallery.new(**opts)) do |gallery|
      count.times { |i| gallery.with_image(src: "/photo-#{i}.jpg", alt: "Photo #{i}") }
    end
  end

  def test_renders_nothing_without_images
    render_gallery(count: 0)
    assert_no_selector "[data-slot='gallery']"
  end

  def test_renders_a_labelled_group_with_the_controller
    render_gallery(label: "Mug photos")
    assert_selector "[data-slot='gallery'][role='group'][aria-label='Mug photos'][data-controller='ui--gallery']"
  end

  def test_each_image_gets_a_slide_a_thumbnail_and_its_alt
    render_gallery
    assert_selector "[data-ui--gallery-target='slide']", count: 3
    assert_selector "[data-ui--gallery-target='thumbnail']", count: 3
    assert_selector "[data-ui--gallery-target='slide'] img[alt='Photo 1'][src='/photo-1.jpg']"
  end

  def test_only_the_first_slide_loads_with_the_page
    render_gallery
    slides = page.all("[data-ui--gallery-target='slide'] img").map { |img| img[:loading] }
    assert_equal %w[eager lazy lazy], slides
  end

  def test_thumbnails_are_decorative_images_in_named_buttons
    render_gallery
    assert_selector "button[aria-label='Show image 2'] img[alt='']"
  end

  def test_only_the_first_thumbnail_starts_current
    render_gallery
    assert_selector "[data-ui--gallery-target='thumbnail'][aria-current='true']", count: 1
    assert_selector "button[aria-label='Show image 1'][aria-current='true']"
  end

  def test_thumbnail_src_and_zoom_src_are_used_where_given
    render_inline(UI::Gallery.new) do |gallery|
      gallery.with_image(src: "/m.jpg", alt: "A", zoom_src: "/large.jpg", thumbnail_src: "/small.jpg")
      gallery.with_image(src: "/n.jpg", alt: "B")
    end
    assert_selector "button[aria-label='Show image 1'] img[src='/small.jpg']"
    assert_selector "[data-ui--gallery-target='slide'][data-zoom-src='/large.jpg']"
    assert_selector "button[aria-label='Show image 2'] img[src='/n.jpg']"
    assert_selector "[data-ui--gallery-target='slide'][data-zoom-src='/n.jpg']"
  end

  def test_the_large_image_is_not_asked_for_until_opened
    render_inline(UI::Gallery.new) { |gallery| gallery.with_image(src: "/m.jpg", alt: "A", zoom_src: "/large.jpg") }
    assert_no_selector "img[src='/large.jpg']", visible: :all
    assert_no_selector "dialog img[src]", visible: :all
  end

  def test_clicking_a_slide_opens_it_at_its_index
    render_gallery
    button = page.find("button[aria-label='Zoom image 2: Photo 1']")
    assert_equal "ui--gallery#open", button["data-action"]
    assert_equal "1", button["data-ui--gallery-index-param"]
    assert_equal "button", button[:type]
  end

  def test_only_the_image_showing_is_a_tab_stop
    render_gallery
    stops = page.all("[data-ui--gallery-target='slide'] button").map { |button| button[:tabindex] }
    assert_equal %w[0 -1 -1], stops
  end

  def test_overlay_is_just_the_image_on_a_transparent_backdrop
    render_gallery
    dialog = page.find("dialog", visible: :all)
    assert_includes dialog[:class], "bg-transparent"
    assert_includes dialog[:class], "backdrop:bg-black/80"
    assert_selector "dialog img", count: 1, visible: :all
    assert_no_selector "dialog [data-ui--gallery-target='thumbnail']", visible: :all
  end

  def test_escape_goes_through_the_closing_animation
    render_gallery
    assert_includes page.find("dialog", visible: :all)["data-action"], "cancel->ui--gallery#cancel"
  end

  def test_overlay_buttons_sit_in_the_top_corners_and_at_the_ends
    render_gallery
    assert_selector "dialog .start-4.top-4 button[aria-label='Zoom in']", visible: :all
    assert_selector "dialog .start-4.top-4 button[aria-label='Zoom out']", visible: :all
    assert_selector "dialog button.end-4.top-4[aria-label='Close']", visible: :all
    assert_selector "dialog button.start-4.top-1\\/2[aria-label='Previous image']", visible: :all
    assert_selector "dialog button.end-4.top-1\\/2[aria-label='Next image']", visible: :all
  end

  def test_overlay_is_the_default_with_no_hover_zoom
    render_gallery
    assert_selector "[data-slot='gallery'][data-zoom='overlay']"
    assert_no_selector "[data-ui--gallery-target='lens']", visible: :all
    assert_no_selector "[data-ui--gallery-target='pane']", visible: :all
    assert_equal "ui--gallery#open", page.find("button[aria-label='Zoom image 1: Photo 0']")["data-action"]
  end

  def test_hover_zoom_adds_a_lens_and_pane_and_still_opens_the_overlay_on_click
    render_gallery(zoom: :hover)
    assert_selector "[data-slot='gallery'][data-zoom='hover'][data-ui--gallery-zoom-scale-value='2.5']"
    assert_selector "[data-ui--gallery-target='lens'].invisible[aria-hidden='true']", visible: :all
    assert_selector "[data-ui--gallery-target='pane'].invisible[aria-hidden='true']", visible: :all
    assert_no_selector "[data-ui--gallery-target='pane'][data-shown]", visible: :all
    action = page.find("button[aria-label='Zoom image 1: Photo 0']")["data-action"]
    assert_includes action, "ui--gallery#open"
    assert_includes action, "pointermove->ui--gallery#hover"
    assert_includes action, "pointerleave->ui--gallery#hoverEnd"
    assert_selector "dialog", visible: :all
  end

  def test_zoom_scale_can_be_set
    render_gallery(zoom: :hover, zoom_scale: 4)
    assert_selector "[data-ui--gallery-zoom-scale-value='4']"
  end

  def test_unknown_zoom_falls_back_to_overlay
    render_gallery(zoom: :spin)
    assert_selector "[data-slot='gallery'][data-zoom='overlay']"
  end

  def test_overlay_is_a_named_dialog_with_its_controls
    render_gallery
    assert_selector "dialog[aria-label='Zoomed image'][data-ui--gallery-target='dialog']", visible: :all
    assert_selector "dialog button[aria-label='Zoom in'][data-action='ui--gallery#zoomIn']", visible: :all
    assert_selector "dialog button[aria-label='Zoom out'][data-action='ui--gallery#zoomOut']", visible: :all
    assert_selector "dialog button[aria-label='Close'][data-action='ui--gallery#close']", visible: :all
  end

  def test_arrows_in_both_views
    render_gallery
    assert_selector "button[aria-label='Previous image'][data-action='ui--gallery#previous']", count: 2, visible: :all
    assert_selector "button[aria-label='Next image'][data-action='ui--gallery#next']", count: 2, visible: :all
  end

  def test_a_single_image_has_no_thumbnails_or_arrows_but_still_zooms
    render_gallery(count: 1)
    assert_no_selector "[data-ui--gallery-target='thumbnail']"
    assert_no_selector "button[aria-label='Next image']", visible: :all
    assert_selector "button[aria-label='Zoom image 1: Photo 0']"
    assert_selector "dialog", visible: :all
  end

  def test_status_says_where_you_are
    render_gallery
    assert_selector "[data-ui--gallery-target='status'][aria-live='polite']", text: "Image 1 of 3"
    assert_equal "Image %{current} of %{total}", page.find("[data-slot='gallery']")["data-ui--gallery-position-value"]
  end

  def test_aspect_and_fit
    { square: "aspect-square", landscape: "aspect-video" }.each do |aspect, css|
      render_gallery(aspect: aspect)
      assert_selector "[data-ui--gallery-target='slide'].#{css}", count: 3
    end
    render_gallery(fit: :cover)
    assert_selector "[data-ui--gallery-target='slide'] img.object-cover", count: 3
  end

  def test_unknown_aspect_and_fit_fall_back
    render_gallery(aspect: :round, fit: :stretch)
    assert_selector "[data-ui--gallery-target='slide'].aspect-square img.object-contain", count: 3
  end

  def test_buttons_keep_the_kits_focus_ring
    render_gallery
    assert_selector "button[aria-label='Show image 1'].focus\\:ring-primary"
    assert_selector "button[aria-label='Next image'].focus\\:ring-primary", count: 1, visible: :all
  end

  def test_overlay_buttons_ring_in_white_to_show_on_the_dark_backdrop
    render_gallery
    assert_selector "dialog button[aria-label='Next image'].focus\\:ring-white", visible: :all
    assert_selector "dialog button[aria-label='Close'].focus\\:ring-white", visible: :all
  end

  def test_class_and_html_attributes_pass_through
    render_gallery(class: "max-w-md", id: "photos", data: { foo: "bar" })
    assert_selector "#photos.max-w-md[data-foo='bar'][data-controller='ui--gallery']"
  end
end

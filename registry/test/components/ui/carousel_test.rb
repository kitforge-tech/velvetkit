# frozen_string_literal: true

require "test_helper"

class UI::CarouselTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_carousel(**opts)
    render_inline(UI::Carousel.new(label: "Highlights", **opts)) do |carousel|
      carousel.with_item { "Coast" }
      carousel.with_item { "Garden" }
      carousel.with_item { "City" }
    end
  end

  def test_a_named_region_of_snapping_items
    render_carousel(item_class: "w-64")
    region = page.find("[role=region][aria-roledescription=carousel][aria-label=Highlights][data-controller='ui--carousel']")
    assert_includes region.find("ul")[:class], "snap-x"
    assert_equal %w[Coast Garden City], page.all("ul li").map(&:text)
    assert_includes page.all("ul li").first[:class], "w-64"
    assert_includes page.all("ul li").first[:class], "snap-start"
  end

  def test_buttons_start_hidden_and_control_the_strip
    render_carousel
    track = page.find("ul")[:id]
    assert_selector "button[aria-label=Previous][hidden][aria-controls='#{track}'][data-action='ui--carousel#previous']", visible: :all
    assert_selector "button[aria-label=Next][hidden][aria-controls='#{track}'] svg[data-icon='chevron-right']", visible: :all
  end

  def test_no_dots_unless_asked
    render_carousel
    assert_no_selector "[data-ui--carousel-target=dot]", visible: :all
    assert_no_selector "[role=group]", visible: :all
  end

  def test_dots_a_hidden_one_for_each_card_until_the_controller_shows_them
    render_carousel(dots: true)
    track = page.find("ul")[:id]
    group = page.find("[role=group][aria-label='Choose a slide']")
    dots = group.all("button[type=button][hidden][data-ui--carousel-target=dot]", visible: :all)
    assert_equal [ "Go to slide 1", "Go to slide 2", "Go to slide 3" ], dots.map { _1[:"aria-label"] }
    assert_equal %w[0 1 2], dots.map { _1[:"data-ui--carousel-index-param"] }
    assert dots.all? { _1[:"aria-controls"] == track && _1[:"data-action"] == "ui--carousel#go" }
  end

  def test_a_dot_has_the_kits_focus_ring_and_lights_when_current
    render_carousel(dots: true)
    classes = page.first("[data-ui--carousel-target=dot]", visible: :all)[:class].split
    assert_includes classes, "focus:ring-2"
    assert_includes classes, "aria-[current=true]:bg-primary"
    assert_includes classes, "aria-[current=true]:w-6"
  end

  # The dots sit under the strip, so the buttons centre on the strip alone.
  def test_the_buttons_centre_on_the_strip_not_the_dots
    render_carousel(dots: true)
    assert_selector "[role=region] > div.relative > ul + button + button", visible: :all
    assert_selector "[role=region] > div.relative + [role=group]", visible: :all
  end

  def test_gap_class_and_attributes
    render_carousel(gap: 6, class: "mt-4", id: "highlights")
    assert_selector "#highlights.mt-4"
    assert_includes page.find("ul")[:class], "gap-6"
  end
end

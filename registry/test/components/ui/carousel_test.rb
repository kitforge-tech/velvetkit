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

  def test_gap_class_and_attributes
    render_carousel(gap: 6, class: "mt-4", id: "highlights")
    assert_selector "#highlights.mt-4"
    assert_includes page.find("ul")[:class], "gap-6"
  end
end

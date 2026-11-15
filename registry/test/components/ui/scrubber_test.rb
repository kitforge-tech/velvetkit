# frozen_string_literal: true

require "test_helper"

class UI::ScrubberTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_scrubber(**opts)
    render_inline(UI::Scrubber.new(label: "Jump to a date", for: "library", **opts)) do |scrubber|
      scrubber.with_mark(href: "#2026-03", label: "March 2026", major: "2026")
      scrubber.with_mark(href: "#2026-02", label: "February 2026")
      scrubber.with_mark(href: "#2025-12", label: "December 2025", major: "2025")
    end
  end

  def test_a_named_nav_watching_what_scrolls
    render_scrubber
    nav = page.find("nav[aria-label='Jump to a date'][data-controller='ui--scrubber']")
    assert_equal "library", nav[:"data-ui--scrubber-for-value"]
  end

  def test_each_mark_links_to_its_heading_and_only_one_is_a_tab_stop
    render_scrubber
    marks = page.all("a[data-ui--scrubber-target=mark]", visible: :all)
    assert_equal %w[#2026-03 #2026-02 #2025-12], marks.map { |mark| mark[:href] }
    assert_equal [ "March 2026", "February 2026", "December 2025" ], marks.map { |mark| mark[:"aria-label"] }
    assert_equal %w[0 -1 -1], marks.map { |mark| mark[:tabindex] }
  end

  def test_majors_show_their_text_and_the_rest_are_dots
    render_scrubber
    assert_selector "a[data-major=true]", text: "2026", visible: :all
    assert_selector "a[data-major=false] span.rounded-full", visible: :all
  end

  def test_the_rail_drags_and_the_tip_and_line_are_hidden_from_screen_readers
    render_scrubber(class: "fixed end-0")
    assert_selector "nav.fixed.end-0 [data-ui--scrubber-target=rail][data-action*='pointerdown->ui--scrubber#grab']"
    assert_selector "[data-ui--scrubber-target=thumb][aria-hidden=true]", visible: :all
    assert_selector "[data-ui--scrubber-target=tip][aria-hidden=true]", visible: :all
  end
end

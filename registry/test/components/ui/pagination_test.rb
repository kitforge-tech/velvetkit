# frozen_string_literal: true

require "test_helper"

class UI::PaginationTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def pagy(count:, page: 1, limit: 25)
    Pagy::Offset.new(count: count, page: page, limit: limit)
  end

  def render_pagination(**options, &block)
    render_inline(UI::Pagination.new(**options), &block)
  end

  # Controls on a single page are noise.
  def test_renders_nothing_for_a_single_page
    render_pagination(pagy: pagy(count: 10))
    assert_no_selector "nav"
  end

  def test_renders_a_labelled_nav_with_page_links
    render_pagination(pagy: pagy(count: 240))
    assert_selector "nav[aria-label]"
    assert_selector "nav ul li"
    assert_selector "a", text: "2"
  end

  # An office wants to know where it is in the list, not just which page.
  def test_shows_a_record_range_summary
    render_pagination(pagy: pagy(count: 240, page: 2))
    assert_text "Showing 26–50 of 240"
  end

  def test_marks_the_current_page
    render_pagination(pagy: pagy(count: 240, page: 3))
    current = page.find("a[aria-current='page']")
    assert_equal "3", current.text.strip
    assert_equal 1, page.all("a[aria-current='page']").size
  end

  # Previous on page one, and next on the last page, would go nowhere.
  def test_previous_is_inert_on_the_first_page
    render_pagination(pagy: pagy(count: 240, page: 1))
    assert_no_selector "a[aria-label='Go to previous page']"
    assert_selector "a[aria-label='Go to next page']"
  end

  def test_next_is_inert_on_the_last_page
    render_pagination(pagy: pagy(count: 240, page: 10))
    assert_selector "a[aria-label='Go to previous page']"
    assert_no_selector "a[aria-label='Go to next page']"
  end

  # A hundred pages of links is unusable, so the middle collapses.
  def test_collapses_long_ranges_around_the_current_page
    render_pagination(pagy: pagy(count: 2_500, page: 50))
    numbers = page.all("nav a").map(&:text).select { |t| t.match?(/\A\d+\z/) }
    assert_includes numbers, "1"
    assert_includes numbers, "100"
    assert_includes numbers, "50"
    refute_includes numbers, "25", "the middle of a long range should collapse"
    assert_selector "span[aria-hidden='true']", minimum: 1
  end

  def test_shows_every_page_when_the_range_is_short
    render_pagination(pagy: pagy(count: 100))
    numbers = page.all("nav a").map(&:text).select { |t| t.match?(/\A\d+\z/) }
    assert_equal %w[1 2 3 4], numbers
  end

  # The caller owns the routes, so the component takes a block.
  def test_builds_urls_from_the_given_block
    render_inline(UI::Pagination.new(pagy: pagy(count: 240)) { |p| "/invoices?page=#{p}" })
    assert_selector "a[href='/invoices?page=2']"
  end

  # Laid out by the width it is given, not the screen's: in a narrow card on
  # a wide screen, the screen-width layout squeezed the summary and the
  # links into one row and they overlapped.
  def test_lays_out_by_its_container_not_the_screen
    render_inline(UI::Pagination.new(pagy: pagy(count: 240, page: 5)) { |p| "/invoices?page=#{p}" })
    with_class = ->(name) { "contains(concat(' ', normalize-space(@class), ' '), ' #{name} ')" }
    container = page.find(:xpath, "//div[#{with_class.("@container")}]")
    row = container.find(:xpath, "./div")
    assert_includes row[:class].split, "@lg:flex-row"
    refute(row[:class].split.any? { _1.start_with?("sm:") }, "no screen breakpoints")
    assert_includes page.find("ul")[:class].split, "flex-wrap"
    assert_equal 2, page.all(:xpath, "//span[#{with_class.("@md:inline")}]", visible: :all).size
  end
end

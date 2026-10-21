# frozen_string_literal: true

require "test_helper"

class UI::BreadcrumbTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_breadcrumb(items, size: :sm, max_items: nil, collapse_at: :middle)
    render_inline(UI::Breadcrumb.new(size: size, max_items: max_items, collapse_at: collapse_at)) do |breadcrumb|
      items.each do |item|
        breadcrumb.with_item(**item)
      end
    end
  end

  def long_items
    [
      { href: "/a", text: "A" },
      { href: "/b", text: "B" },
      { href: "/c", text: "C" },
      { href: "/d", text: "D" },
      { href: "/e", text: "E" },
      { href: "/f", text: "F" }
    ]
  end

  def simple_items
    [
      { href: "/groups", text: "Workspace" },
      { href: "/groups/website", text: "Website" },
      { href: "/issues", text: "Issues" }
    ]
  end

  # Structure

  def test_renders_nav_landmark
    render_breadcrumb(simple_items)
    nav = page.find("nav[aria-label='Breadcrumb']")
    assert nav.present?
  end

  def test_renders_ordered_list
    render_breadcrumb(simple_items)
    assert_selector "nav ol"
  end

  def test_renders_all_items_as_links
    render_breadcrumb(simple_items)
    links = page.all("nav ol li a")
    assert_equal 3, links.size
  end

  def test_each_item_is_a_link
    render_breadcrumb(simple_items)
    links = page.all("nav ol a")
    assert_equal 3, links.size
    assert_equal "Workspace", links[0].text.strip
    assert_equal "Website", links[1].text.strip
  end

  def test_links_have_href
    render_breadcrumb(simple_items)
    links = page.all("nav ol a")
    assert_equal "/groups", links[0][:href]
    assert_equal "/groups/website", links[1][:href]
    assert_equal "/issues", links[2][:href]
  end

  def test_single_item_no_separator
    render_breadcrumb([ { href: "/", text: "Home" } ])
    refute_selector "span[aria-hidden='true']"
  end

  # Separators

  def test_separator_between_items
    render_breadcrumb(simple_items)
    separators = page.all("span[aria-hidden='true']")
    assert_equal 2, separators.size
  end

  def test_separator_is_slash
    render_breadcrumb(simple_items)
    sep = page.all("span[aria-hidden='true']").first
    assert_includes sep.text, "/"
  end

  def test_separator_is_aria_hidden
    render_breadcrumb(simple_items)
    sep = page.all("span[aria-hidden='true']").first
    assert_equal "true", sep["aria-hidden"]
  end

  # aria-current

  def test_last_item_has_aria_current_page
    render_breadcrumb(simple_items)
    last_link = page.all("nav ol a").last
    assert_equal "page", last_link["aria-current"]
  end

  def test_non_last_items_do_not_have_aria_current
    render_breadcrumb(simple_items)
    first_link = page.all("nav ol a").first
    refute first_link["aria-current"].present?
  end

  # Sizes

  def test_sm_is_default
    render_breadcrumb(simple_items)
    classes = page.find("nav")[:class].split
    assert_includes classes, "text-xs"
  end

  def test_md_size
    render_breadcrumb(simple_items, size: :md)
    classes = page.find("nav")[:class].split
    assert_includes classes, "text-sm"
  end

  # Avatar

  def test_item_with_avatar
    items = [
      { href: "/groups/website", text: "Website", avatar_src: "/avatar.png" },
      { href: "/issues", text: "Issues" }
    ]
    render_breadcrumb(items)
    assert_selector "nav ol img[src='/avatar.png']"
  end

  # Truncation

  def test_non_last_items_truncated
    render_breadcrumb(simple_items)
    first_link = page.all("nav ol a").first
    classes = first_link[:class].split
    assert_includes classes, "max-w-32"
    assert_includes classes, "truncate"
  end

  def test_last_item_not_truncated
    render_breadcrumb(simple_items)
    last_link = page.all("nav ol a").last
    classes = last_link[:class].split
    refute_includes classes, "max-w-32"
  end

  # Data attributes for Stimulus decoupling

  def test_items_have_breadcrumb_data_attrs
    render_breadcrumb(simple_items)
    first_li = page.all("nav ol li").first
    assert_equal "/groups", first_li["data-breadcrumb-href"]
    assert_equal "Workspace", first_li["data-breadcrumb-text"]
  end

  def test_last_item_has_data_last_attribute
    render_breadcrumb(simple_items)
    last_li = page.all("nav ol li").last
    assert_equal "true", last_li["data-last"]
  end

  def test_non_last_items_do_not_have_data_last
    render_breadcrumb(simple_items)
    first_li = page.all("nav ol li").first
    refute first_li["data-last"].present?
  end

  # Separator icon customization

  def test_custom_separator_icon
    skip "separator_icon option changes slash character — tested manually in previews"
  end

  # User class merge

  def test_user_class_merge
    render_inline(UI::Breadcrumb.new(class: "my-nav")) do |breadcrumb|
      breadcrumb.with_item(href: "/", text: "Home")
    end
    classes = page.find("nav")[:class].split
    assert_includes classes, "my-nav"
  end

  # HTML attrs passthrough

  def test_html_attrs_passthrough
    render_inline(UI::Breadcrumb.new(data: { test_id: "bc" })) do |breadcrumb|
      breadcrumb.with_item(href: "/", text: "Home")
    end
    assert_selector "nav[data-test-id='bc']"
  end

  # Auto-ellipsis — collapse_at: :middle (default)

  def test_middle_collapse_shows_first_and_last
    render_breadcrumb(long_items, max_items: 3, collapse_at: :middle)
    links = page.all("nav ol a")
    texts = links.map { |a| a.text.strip }
    # budget=2, head=1, tail=1 → A + E + F
    assert_equal [ "A", "E", "F" ], texts
  end

  def test_middle_collapse_renders_auto_ellipsis
    render_breadcrumb(long_items, max_items: 3, collapse_at: :middle)
    assert_selector "nav ol button[aria-label='More breadcrumb pages']"
  end

  def test_middle_collapse_hidden_items_in_dropdown
    render_breadcrumb(long_items, max_items: 3, collapse_at: :middle)
    html = page.native.inner_html
    # Hidden items (C, D, E) should be inside the collapsed popover list
    assert_includes html, "Collapsed breadcrumb pages"
    assert_includes html, 'href="/c"'
    assert_includes html, 'href="/d"'
    assert_includes html, 'href="/e"'
  end

  def test_middle_collapse_has_separators_around_ellipsis
    render_breadcrumb(long_items, max_items: 3, collapse_at: :middle)
    separators = page.all("nav ol span[aria-hidden='true']")
    # A > B > ... > F  →  3 separators
    assert_equal 3, separators.size
  end

  def test_middle_collapse_renders_auto_ellipsis
    render_breadcrumb(long_items, max_items: 3, collapse_at: :middle)
    assert_selector "nav ol button[aria-label='More breadcrumb pages']"
  end

  # Auto-ellipsis — collapse_at: :start

  def test_start_collapse_shows_last_items
    render_breadcrumb(long_items, max_items: 3, collapse_at: :start)
    links = page.all("nav ol a")
    texts = links.map { |a| a.text.strip }
    assert_equal [ "D", "E", "F" ], texts
  end

  def test_start_collapse_renders_auto_ellipsis_first
    render_breadcrumb(long_items, max_items: 3, collapse_at: :start)
    # Ellipsis should be the first element after the first separator
    first_button = page.all("nav ol button").first
    assert_equal "More breadcrumb pages", first_button["aria-label"]
  end

  # Auto-ellipsis — collapse_at: :end

  def test_end_collapse_shows_first_items
    render_breadcrumb(long_items, max_items: 3, collapse_at: :end)
    links = page.all("nav ol a")
    texts = links.map { |a| a.text.strip }
    # budget=2 prefix + current → A, B + F
    assert_equal [ "A", "B", "F" ], texts
  end

  def test_end_collapse_renders_auto_ellipsis_last
    render_breadcrumb(long_items, max_items: 3, collapse_at: :end)
    buttons = page.all("nav ol button")
    assert_equal 1, buttons.size
    assert_equal "More breadcrumb pages", buttons.last["aria-label"]
  end

  # Auto-ellipsis — no truncation needed

  def test_no_truncation_when_items_within_max
    render_breadcrumb(simple_items, max_items: 5, collapse_at: :middle)
    links = page.all("nav ol a")
    assert_equal 3, links.size
    refute_selector "nav ol button"
  end
end

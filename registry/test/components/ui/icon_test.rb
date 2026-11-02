# frozen_string_literal: true

require "test_helper"

class UI::IconTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_draws_the_svg_file_inline
    render_inline UI::Icon.new(name: "x")
    svg = page.find("svg[data-icon='x']", visible: :all)
    assert svg.has_selector?("path", visible: :all, minimum: 1), "draws the file's shapes"
    assert svg[:viewbox].present?, "keeps the file's viewBox"
  end

  def test_drops_the_files_own_size_and_class
    render_inline UI::Icon.new(name: "x")
    svg = page.find("svg", visible: :all)
    assert_nil svg[:width]
    assert_nil svg[:height]
    assert_equal %w[h-5 inline-block shrink-0 w-5], svg[:class].split.sort
  end

  def test_decorative_by_default
    render_inline UI::Icon.new(name: "x")
    svg = page.find("svg", visible: :all)
    assert_equal "true", svg["aria-hidden"]
    assert_nil svg[:role]
  end

  def test_label_makes_it_an_image
    render_inline UI::Icon.new(name: "x", label: "Close")
    svg = page.find("svg", visible: :all)
    assert_equal "img", svg[:role]
    assert_equal "Close", svg["aria-label"]
    assert_nil svg["aria-hidden"]
  end

  def test_symbol_names
    render_inline UI::Icon.new(name: :x)
    assert_selector "svg[data-icon='x'] path", visible: :all
  end

  def test_an_icon_with_no_file_draws_a_placeholder
    render_inline UI::Icon.new(name: "no-such-icon")
    svg = page.find("svg[data-icon='no-such-icon']", visible: :all)
    assert svg["data-icon-missing"]
    assert svg.has_selector?("rect", visible: :all)
  end

  def test_a_name_is_never_a_path
    render_inline UI::Icon.new(name: "../icons/lucide/x")
    assert_selector "svg[data-icon-missing]", visible: :all
    assert_no_selector "path", visible: :all
  end

  def test_default_size_classes
    render_inline UI::Icon.new(name: "menu")
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "w-5"
    assert_includes classes, "h-5"
  end

  def test_size_xs
    render_inline UI::Icon.new(name: "menu", size: :xs)
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "w-3"
    assert_includes classes, "h-3"
  end

  def test_size_sm
    render_inline UI::Icon.new(name: "menu", size: :sm)
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "w-4"
    assert_includes classes, "h-4"
  end

  def test_size_lg
    render_inline UI::Icon.new(name: "menu", size: :lg)
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "w-6"
    assert_includes classes, "h-6"
  end

  def test_size_xl
    render_inline UI::Icon.new(name: "menu", size: :xl)
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "w-8"
    assert_includes classes, "h-8"
  end

  def test_user_class_merges
    render_inline UI::Icon.new(name: "menu", class: "text-red-500")
    classes = page.find("svg", visible: :all)[:class].split
    assert_includes classes, "text-red-500"
    assert_includes classes, "w-5"
  end

  def test_renders_nothing_when_name_blank
    render_inline UI::Icon.new(name: "")
    assert_no_selector "svg", visible: :all
  end

  def test_renders_nothing_when_name_nil
    render_inline UI::Icon.new(name: nil)
    assert_no_selector "svg", visible: :all
  end

  def test_html_attrs_pass_through
    render_inline UI::Icon.new(name: "menu", id: "header-menu", aria: { label: "Open menu" })
    svg = page.find("svg", visible: :all)
    assert_equal "header-menu", svg[:id]
    assert_equal "Open menu", svg["aria-label"]
  end

  def test_data_attributes_keep_the_icon_name
    render_inline(UI::Icon.new(name: "copy", data: { clipboard_target: "idle" }))
    svg = page.find("svg", visible: :all)
    assert svg.matches_css?("[data-icon='copy']")
    assert_equal "idle", svg["data-clipboard-target"]
  end
end

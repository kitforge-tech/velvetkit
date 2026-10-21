# frozen_string_literal: true

require "test_helper"

class UI::IconTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_i_tag_with_lucide_data_attribute
    render_inline UI::Icon.new(name: "menu")
    icon = page.find("i", visible: :all)
    assert_equal "menu", icon["data-lucide"]
  end

  def test_default_size_classes
    render_inline UI::Icon.new(name: "menu")
    icon = page.find("i", visible: :all)
    classes = icon[:class].split
    assert_includes classes, "w-5"
    assert_includes classes, "h-5"
  end

  def test_size_xs
    render_inline UI::Icon.new(name: "menu", size: :xs)
    icon = page.find("i", visible: :all)
    classes = icon[:class].split
    assert_includes classes, "w-3"
    assert_includes classes, "h-3"
  end

  def test_size_sm
    render_inline UI::Icon.new(name: "menu", size: :sm)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-4"
    assert_includes classes, "h-4"
  end

  def test_size_lg
    render_inline UI::Icon.new(name: "menu", size: :lg)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-6"
    assert_includes classes, "h-6"
  end

  def test_size_xl
    render_inline UI::Icon.new(name: "menu", size: :xl)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-8"
    assert_includes classes, "h-8"
  end

  def test_user_class_merges
    render_inline UI::Icon.new(name: "menu", class: "text-red-500")
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "text-red-500"
    assert_includes classes, "w-5"
  end

  def test_renders_nothing_when_name_blank
    render_inline UI::Icon.new(name: "")
    assert_no_selector "i", visible: :all
  end

  def test_renders_nothing_when_name_nil
    render_inline UI::Icon.new(name: nil)
    assert_no_selector "i", visible: :all
  end

  def test_html_attrs_pass_through
    render_inline UI::Icon.new(name: "menu", id: "header-menu", aria: { label: "Open menu" })
    icon = page.find("i", visible: :all)
    assert_equal "header-menu", icon[:id]
    assert_equal "Open menu", icon["aria-label"]
  end

  def test_data_attributes_keep_the_icon_name
    render_inline(UI::Icon.new(name: "copy", data: { clipboard_target: "idle" }))
    icon = page.find("i", visible: :all)
    assert_equal "copy", icon["data-lucide"]
    assert_equal "idle", icon["data-clipboard-target"]
  end
end

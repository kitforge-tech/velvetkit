# frozen_string_literal: true

require "test_helper"

class UI::SpinnerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_loader_icon_with_animate_spin
    render_inline UI::Spinner.new
    icon = page.find("i", visible: :all)
    assert_equal "loader", icon["data-lucide"]
    assert_includes icon[:class].split, "animate-spin"
  end

  def test_default_size_classes
    render_inline UI::Spinner.new
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-5"
    assert_includes classes, "h-5"
  end

  def test_size_xs
    render_inline UI::Spinner.new(size: :xs)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-3"
    assert_includes classes, "h-3"
  end

  def test_size_sm
    render_inline UI::Spinner.new(size: :sm)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-4"
    assert_includes classes, "h-4"
  end

  def test_size_lg
    render_inline UI::Spinner.new(size: :lg)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-6"
    assert_includes classes, "h-6"
  end

  def test_size_xl
    render_inline UI::Spinner.new(size: :xl)
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "w-8"
    assert_includes classes, "h-8"
  end

  def test_user_class_merges
    render_inline UI::Spinner.new(class: "text-primary")
    classes = page.find("i", visible: :all)[:class].split
    assert_includes classes, "text-primary"
    assert_includes classes, "animate-spin"
  end

  def test_html_attrs_pass_through
    render_inline UI::Spinner.new(aria: { label: "Loading" })
    icon = page.find("i", visible: :all)
    assert_equal "Loading", icon["aria-label"]
  end
end

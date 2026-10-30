# frozen_string_literal: true

require "test_helper"

class UI::SkeletonTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def skeleton_el
    page.find("div", visible: :all)
  end

  def test_renders_a_div
    render_inline(UI::Skeleton.new)
    assert skeleton_el.present?
  end

  def test_pulses_regardless_of_shape
    render_inline(UI::Skeleton.new)
    assert_includes skeleton_el[:class].split, "animate-pulse"
  end

  def test_hidden_from_screen_readers
    render_inline(UI::Skeleton.new)
    assert_equal "true", skeleton_el["aria-hidden"]
  end

  def test_default_shape_is_text
    render_inline(UI::Skeleton.new)
    classes = skeleton_el[:class].split
    assert_includes classes, "h-4"
    assert_includes classes, "w-full"
  end

  def test_circle_shape
    render_inline(UI::Skeleton.new(shape: :circle))
    classes = skeleton_el[:class].split
    assert_includes classes, "size-10"
    assert_includes classes, "rounded-full"
  end

  def test_rectangle_shape
    render_inline(UI::Skeleton.new(shape: :rectangle))
    classes = skeleton_el[:class].split
    assert_includes classes, "h-24"
    assert_includes classes, "w-full"
  end

  def test_user_class_merge
    render_inline(UI::Skeleton.new(class: "w-32"))
    assert_includes skeleton_el[:class].split, "w-32"
  end

  def test_user_class_overrides_shape_sizing_via_tailwind_merge
    render_inline(UI::Skeleton.new(shape: :text, class: "h-10"))
    classes = skeleton_el[:class].split
    assert_includes classes, "h-10"
    refute_includes classes, "h-4"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Skeleton.new(id: "my-id", data: { test_id: "s" }))
    assert_selector "div#my-id[data-test-id='s']"
  end
end

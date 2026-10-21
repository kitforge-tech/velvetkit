# frozen_string_literal: true

require "test_helper"

class UI::AvatarTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def avatar_el
    page.find("[data-slot='avatar']")
  end

  def test_renders_span
    render_inline(UI::Avatar.new) { "JD" }
    assert avatar_el.present?
  end

  def test_default_shape_is_circle
    render_inline(UI::Avatar.new) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "rounded-full"
  end

  def test_rounded_shape
    render_inline(UI::Avatar.new(shape: :rounded)) { "PJ" }
    classes = avatar_el[:class].split
    assert_includes classes, "rounded-md"
  end

  def test_sm_size
    render_inline(UI::Avatar.new(size: :sm)) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "h-6"
    assert_includes classes, "w-6"
  end

  def test_default_size
    render_inline(UI::Avatar.new) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "h-10"
    assert_includes classes, "w-10"
  end

  def test_default_color
    render_inline(UI::Avatar.new) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "bg-muted"
    assert_includes classes, "text-foreground/70"
  end

  def test_primary_color
    render_inline(UI::Avatar.new(color: :primary)) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "bg-primary"
    assert_includes classes, "text-primary-foreground"
  end

  def test_destructive_color
    render_inline(UI::Avatar.new(color: :destructive)) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "bg-destructive"
    assert_includes classes, "text-white"
  end

  def test_amber_color
    render_inline(UI::Avatar.new(color: :amber)) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "bg-amber-500"
    assert_includes classes, "text-white"
  end

  def test_fallback_is_aria_hidden
    render_inline(UI::Avatar.new) { "JD" }
    fallback = avatar_el.find("span")
    assert_equal "true", fallback["aria-hidden"]
  end

  def test_standalone_with_alt_gets_role_img
    render_inline(UI::Avatar.new(alt: "John Doe")) { "JD" }
    assert_equal "img", avatar_el[:role]
    assert_equal "John Doe", avatar_el["aria-label"]
  end

  def test_standalone_without_alt_has_no_role
    render_inline(UI::Avatar.new) { "JD" }
    refute avatar_el[:role].present?
  end

  def test_image_slot
    render_inline(UI::Avatar.new) do |avatar|
      avatar.with_image(src: "https://example.com/avatar.jpg", alt: "Jane Doe")
    end
    assert_selector "[data-slot='avatar'] img[src='https://example.com/avatar.jpg'][alt='Jane Doe']"
  end

  def test_image_prevents_fallback
    render_inline(UI::Avatar.new) do |avatar|
      avatar.with_image(src: "https://example.com/avatar.jpg")
    end
    assert_selector "[data-slot='avatar'] img"
    assert_equal 0, avatar_el.all("span").size
  end

  def test_fallback_slot_overrides_default
    render_inline(UI::Avatar.new) do |avatar|
      avatar.with_fallback { "FB" }
    end
    assert_selector "[data-slot='avatar'] > span", text: "FB"
  end

  def test_user_class_merge
    render_inline(UI::Avatar.new(class: "border-2")) { "JD" }
    classes = avatar_el[:class].split
    assert_includes classes, "border-2"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Avatar.new(id: "my-avatar", data: { test_id: "av" })) { "JD" }
    assert_selector "[data-slot='avatar']#my-avatar[data-test-id='av']"
  end

  # Fills the gap between sm (24px) and default (40px).
  def test_size_md
    render_inline(UI::Avatar.new(size: :md)) { "JD" }
    classes = page.find("[data-slot='avatar']")[:class].split
    assert_includes classes, "h-8"
    assert_includes classes, "w-8"
  end
end

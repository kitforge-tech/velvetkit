# frozen_string_literal: true

require "test_helper"

class UI::TextTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_paragraph_by_default
    render_inline(UI::Text.new) { "Hello world" }
    assert_selector "p", text: "Hello world"
  end

  def test_renders_as_span
    render_inline(UI::Text.new(as: :span)) { "Inline text" }
    assert_selector "span", text: "Inline text"
  end

  def test_renders_as_div
    render_inline(UI::Text.new(as: :div)) { "Block text" }
    assert_selector "div", text: "Block text"
  end

  def test_default_classes
    render_inline(UI::Text.new) { "x" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-base"
    assert_includes classes, "font-normal"
    assert_includes classes, "text-foreground"
    # Note: leading-normal is in base but tailwind_merge may remove it
  end

  def test_size_variants
    render_inline(UI::Text.new(size: :sm)) { "Small" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-sm"
    refute_includes classes, "text-base"
  end

  def test_weight_variants
    render_inline(UI::Text.new(weight: :bold)) { "Bold" }
    classes = page.find("p")[:class].split
    assert_includes classes, "font-bold"
    refute_includes classes, "font-normal"
  end

  def test_tone_variants
    render_inline(UI::Text.new(tone: :muted)) { "Muted" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-muted-foreground"
    refute_includes classes, "text-foreground"
  end

  def test_destructive_tone
    render_inline(UI::Text.new(tone: :destructive)) { "Error" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-destructive"
  end

  def test_user_class_merge
    render_inline(UI::Text.new(class: "text-center")) { "Centered" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-center"
  end

  def test_user_class_overrides_defaults
    render_inline(UI::Text.new(class: "font-light")) { "Light" }
    classes = page.find("p")[:class].split
    refute_includes classes, "font-normal"
    assert_includes classes, "font-light"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Text.new(id: "my-text", data: { test: "x" })) { "y" }
    assert_selector "p#my-text[data-test='x']"
  end

  def test_large_heading_size
    render_inline(UI::Text.new(size: :"4xl", weight: :bold)) { "Hero" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-4xl"
    assert_includes classes, "font-bold"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::BadgeTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_span_with_default_classes
    render_inline(UI::Badge.new) { "New" }
    span = page.find("span")
    classes = span[:class].split
    assert_includes classes, "bg-primary"
    assert_includes classes, "rounded-full"
    assert_equal "New", span.text.strip
  end

  def test_outline_variant_has_border_and_no_bg
    render_inline(UI::Badge.new(variant: :outline)) { "x" }
    classes = page.find("span")[:class].split
    assert_includes classes, "border-input"
    refute_includes classes, "bg-primary"
  end

  def test_secondary_variant
    render_inline(UI::Badge.new(variant: :secondary)) { "Secondary" }
    classes = page.find("span")[:class].split
    assert_includes classes, "bg-secondary"
    assert_includes classes, "text-secondary-foreground"
  end

  def test_destructive_variant
    render_inline(UI::Badge.new(variant: :destructive)) { "Error" }
    classes = page.find("span")[:class].split
    assert_includes classes, "bg-destructive"
    assert_includes classes, "text-white"
    refute_includes classes, "bg-primary"
  end

  def test_success_variant
    render_inline(UI::Badge.new(variant: :success)) { "OK" }
    classes = page.find("span")[:class].split
    assert_includes classes, "bg-emerald-500"
    assert_includes classes, "text-white"
  end

  def test_warning_variant
    render_inline(UI::Badge.new(variant: :warning)) { "Warn" }
    classes = page.find("span")[:class].split
    assert_includes classes, "bg-amber-500"
    assert_includes classes, "text-white"
  end

  def test_size_sm
    render_inline(UI::Badge.new(size: :sm)) { "Tiny" }
    classes = page.find("span")[:class].split
    assert_includes classes, "h-5"
    assert_includes classes, "px-1.5"
    assert_includes classes, "text-[10px]"
  end

  def test_size_lg
    render_inline(UI::Badge.new(size: :lg)) { "Large" }
    classes = page.find("span")[:class].split
    assert_includes classes, "h-7"
    assert_includes classes, "px-2.5"
    assert_includes classes, "text-sm"
  end

  def test_leading_icon_slot
    render_inline(UI::Badge.new) do |badge|
      badge.with_leading_icon(name: "badge-check")
      "Verified"
    end
    span = page.find("span")
    icon = span.find("i", visible: :all)
    assert_equal "badge-check", icon["data-lucide"]
    assert_match(/<i[^>]*data-lucide="badge-check".*Verified/m, span.native.to_html)
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::Badge.new(class: "bg-red-500")) { "Custom" }
    classes = page.find("span")[:class].split
    refute_includes classes, "bg-primary"
    assert_includes classes, "bg-red-500"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Badge.new(id: "my-badge", data: { test_id: "badge-x" })) { "x" }
    assert_selector "span#my-badge[data-test-id='badge-x']"
  end

  def test_default_size_classes
    render_inline(UI::Badge.new) { "Default" }
    classes = page.find("span")[:class].split
    assert_includes classes, "h-6"
    assert_includes classes, "px-2"
    assert_includes classes, "text-xs"
  end

  def test_base_class_structure
    render_inline(UI::Badge.new) { "Base" }
    classes = page.find("span")[:class].split
    assert_includes classes, "inline-flex"
    assert_includes classes, "rounded-full"
    assert_includes classes, "font-medium"
    assert_includes classes, "whitespace-nowrap"
    assert_includes classes, "border"
    assert_includes classes, "border-transparent"
    assert_includes classes, "transition-colors"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::LinkTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_default_link_variant
    render_inline(UI::Link.new(href: "/docs")) { "Learn more" }
    link = page.find("a", text: "Learn more")
    classes = link[:class].split
    assert_equal "/docs", link[:href]
    assert_includes classes, "text-primary"
    assert_includes classes, "underline-offset-4"
    refute_includes classes, "px-3"
    refute_includes classes, "px-4"
    refute_includes classes, "px-8"
    refute_includes classes, "py-2"
    refute_includes classes, "h-8"
    refute_includes classes, "h-9"
    refute_includes classes, "h-10"
  end

  def test_renders_button_style_default_variant
    render_inline(UI::Link.new(href: "/signup", variant: :default, button_variant: true)) { "Sign up" }
    link = page.find("a", text: "Sign up")
    classes = link[:class].split
    assert_includes classes, "bg-primary"
    assert_includes classes, "text-primary-foreground"
  end

  def test_renders_outline_variant
    render_inline(UI::Link.new(variant: :outline, button_variant: true)) { "Outline" }
    link = page.find("a", text: "Outline")
    classes = link[:class].split
    assert_includes classes, "border"
    assert_includes classes, "bg-background"
  end

  def test_renders_destructive_variant
    render_inline(UI::Link.new(variant: :destructive, button_variant: true)) { "Delete" }
    link = page.find("a", text: "Delete")
    classes = link[:class].split
    assert_includes classes, "bg-destructive"
    assert_includes classes, "focus-visible:ring-destructive"
  end

  def test_size_sm
    render_inline(UI::Link.new(size: :sm, button_variant: true)) { "Small" }
    classes = page.find("a", text: "Small")[:class].split
    assert_includes classes, "h-8"
    assert_includes classes, "text-xs"
  end

  def test_size_lg
    render_inline(UI::Link.new(size: :lg, button_variant: true)) { "Large" }
    classes = page.find("a", text: "Large")[:class].split
    assert_includes classes, "h-10"
    assert_includes classes, "px-8"
  end

  def test_user_class_overrides_default
    render_inline(UI::Link.new(class: "bg-red-500", variant: :default, button_variant: true)) { "Custom" }
    classes = page.find("a", text: "Custom")[:class].split
    refute_includes classes, "bg-primary"
    assert_includes classes, "bg-red-500"
  end

  def test_html_attrs_pass_through
    render_inline(UI::Link.new(id: "docs-link", data: { test_id: "docs" }, target: "_blank")) { "Docs" }
    assert_selector "a#docs-link[data-test-id='docs'][target='_blank']", text: "Docs"
  end

  def test_leading_icon_renders_before_content
    render_inline(UI::Link.new(href: "/next")) do |link|
      link.with_leading_icon(name: "arrow-right")
      "Continue"
    end

    anchor = page.find("a", text: "Continue")
    assert_equal "arrow-right", anchor.find("i", visible: :all)["data-lucide"]
    assert_match(/<i[^>]*data-lucide="arrow-right".*Continue/m, anchor.native.to_html)
  end

  def test_trailing_icon_renders_after_content
    render_inline(UI::Link.new(href: "/next")) do |link|
      link.with_trailing_icon(name: "arrow-right")
      "Continue"
    end

    anchor = page.find("a", text: "Continue")
    assert_match(/Continue.*<i[^>]*data-lucide="arrow-right"/m, anchor.native.to_html)
  end
end

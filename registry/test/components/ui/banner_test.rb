# frozen_string_literal: true

require "test_helper"

class UI::BannerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def banner_el
    page.find("[data-slot='banner']")
  end

  def test_renders_container
    render_inline(UI::Banner.new) { "Message" }
    assert banner_el.present?
  end

  def test_default_variant_is_introduction
    render_inline(UI::Banner.new) { "x" }
    classes = banner_el[:class].split
    assert_includes classes, "bg-primary/10"
    assert_includes classes, "border-primary/20"
  end

  def test_promotion_variant
    render_inline(UI::Banner.new(variant: :promotion)) { "x" }
    classes = banner_el[:class].split
    assert_includes classes, "bg-accent"
    assert_includes classes, "border-accent-foreground/20"
  end

  def test_full_width
    render_inline(UI::Banner.new(full_width: true)) { "x" }
    classes = banner_el[:class].split
    assert_includes classes, "w-full"
  end

  def test_not_full_width_by_default
    render_inline(UI::Banner.new) { "x" }
    classes = banner_el[:class].split
    refute_includes classes, "w-full"
  end

  def test_renders_without_body_text
    render_inline(UI::Banner.new) do |banner|
      banner.with_title { "Just a title" }
    end
    assert_selector "[data-slot='banner'] h4", text: "Just a title"
    refute_selector "[data-slot='banner'] p"
  end

  def test_renders_title_slot
    render_inline(UI::Banner.new) do |banner|
      banner.with_title { "Try new feature" }
      "Description here."
    end
    assert_selector "h4", text: "Try new feature"
    assert_selector "[data-slot='banner'] p", text: /Description here/
  end

  def test_renders_action_slot
    render_inline(UI::Banner.new) do |banner|
      banner.with_action { "Get started" }
    end
    assert_selector "[data-slot='banner'] div", text: "Get started"
  end

  def test_renders_illustration_slot
    render_inline(UI::Banner.new) do |banner|
      banner.with_illustration do
        "<img src='test.svg' alt='' />".html_safe
      end
    end
    assert_selector "[data-slot='banner'] img[src='test.svg']"
  end

  def test_renders_leading_icon_slot
    render_inline(UI::Banner.new) do |banner|
      banner.with_leading_icon(name: "info")
    end
    assert_selector "[data-slot='banner'] i[data-lucide='info']"
  end

  def test_dismiss_button_uses_button_component
    render_inline(UI::Banner.new) { "Message" }
    assert_selector "button[aria-label='Dismiss']"
    assert_selector "button[aria-label='Dismiss'] i[data-lucide='x']"
  end

  def test_dismiss_button_wired_to_controller
    render_inline(UI::Banner.new) { "x" }
    dismiss = page.find("button[aria-label='Dismiss']")
    assert_includes dismiss["data-action"], "ui--banner#dismiss"
  end

  def test_custom_dismiss_icon
    render_inline(UI::Banner.new(dismiss_icon: "check")) { "x" }
    assert_selector "button[aria-label='Dismiss'] i[data-lucide='check']"
  end

  def test_dismissible_false_hides_close
    render_inline(UI::Banner.new(dismissible: false)) { "x" }
    refute_selector "button[aria-label='Dismiss']"
  end

  def test_user_class_merge
    render_inline(UI::Banner.new(class: "my-banner")) { "x" }
    classes = banner_el[:class].split
    assert_includes classes, "my-banner"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Banner.new(id: "my-id", data: { test_id: "b" })) { "x" }
    assert_selector "[data-slot='banner']#my-id[data-test-id='b']"
  end
end

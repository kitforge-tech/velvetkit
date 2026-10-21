# frozen_string_literal: true

require "test_helper"

class UI::ButtonToTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_a_post_form_with_a_submit_button
    render_inline(UI::ButtonTo.new("/session")) { "Continue" }
    assert_selector "form[method='post'][action='/session']"
    assert_selector "button[type='submit']", text: "Continue"
  end

  def test_inherits_button_variant_classes
    render_inline(UI::ButtonTo.new("/session", variant: :outline)) { "Continue" }
    classes = page.find("button")[:class].split
    assert_includes classes, "border"
    assert_includes classes, "border-input"
  end

  def test_full_width
    render_inline(UI::ButtonTo.new("/session", full_width: true)) { "Continue" }
    assert_includes page.find("button")[:class].split, "w-full"
  end

  def test_form_class_lands_on_the_form_not_the_button
    render_inline(UI::ButtonTo.new("/session", form_class: "w-full")) { "Continue" }
    assert_includes page.find("form")[:class].split, "w-full"
    refute_includes page.find("button")[:class].split, "form-class"
  end

  # Velvet::ButtonTo inherited these slots but its template never rendered them.
  def test_renders_leading_icon_slot
    render_inline(UI::ButtonTo.new("/session")) do |button|
      button.with_leading_icon(name: "mail")
      "Continue"
    end
    assert_selector "button i[data-lucide='mail']"
  end

  def test_renders_trailing_icon_slot
    render_inline(UI::ButtonTo.new("/session")) do |button|
      button.with_trailing_icon(name: "arrow-right")
      "Continue"
    end
    assert_selector "button i[data-lucide='arrow-right']"
  end

  def test_loading_state_shows_spinner_and_disables
    render_inline(UI::ButtonTo.new("/session", loading: true)) { "Continue" }
    button = page.find("button")
    assert_equal "true", button[:"aria-busy"]
    assert button[:disabled].present?
    assert_selector "button .sr-only", text: "Loading, please wait"
  end

  def test_disabled
    render_inline(UI::ButtonTo.new("/session", disabled: true)) { "Continue" }
    assert page.find("button")[:disabled].present?
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::ButtonTo.new("/session", class: "bg-red-500")) { "Continue" }
    classes = page.find("button")[:class].split
    assert_includes classes, "bg-red-500"
    refute_includes classes, "bg-primary"
  end

  def test_html_attrs_passthrough
    render_inline(UI::ButtonTo.new("/session", data: { turbo: false })) { "Continue" }
    assert_selector "button[data-turbo='false']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::AlertTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div_with_role_alert
    render_inline(UI::Alert.new) { "Default alert" }
    div = page.find("[role='alert']")
    assert div.present?
  end

  def test_default_variant_classes
    render_inline(UI::Alert.new) { "x" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "bg-background"
    assert_includes classes, "text-foreground"
    assert_includes classes, "border-input"
  end

  def test_destructive_variant
    render_inline(UI::Alert.new(variant: :destructive)) { "Error" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "bg-destructive/10"
    assert_includes classes, "text-destructive"
    assert_includes classes, "border-destructive/30"
  end

  def test_warning_variant
    render_inline(UI::Alert.new(variant: :warning)) { "Warn" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "bg-amber-50"
    assert_includes classes, "text-amber-800"
    assert_includes classes, "border-amber-300"
  end

  def test_success_variant
    render_inline(UI::Alert.new(variant: :success)) { "OK" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "bg-emerald-50"
    assert_includes classes, "text-emerald-800"
    assert_includes classes, "border-emerald-300"
  end

  def test_info_variant
    render_inline(UI::Alert.new(variant: :info)) { "Info" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "bg-sky-50"
    assert_includes classes, "text-sky-800"
    assert_includes classes, "border-sky-300"
  end

  def test_default_variant_renders_default_icon_info
    render_inline(UI::Alert.new) { "Default" }
    icons = page.all("i", visible: :all)
    assert_equal 1, icons.size
    assert_equal "info", icons.first["data-lucide"]
  end

  def test_destructive_variant_renders_circle_alert_icon
    render_inline(UI::Alert.new(variant: :destructive)) { "Error" }
    icons = page.all("i", visible: :all)
    assert_equal 1, icons.size
    assert_equal "circle-alert", icons.first["data-lucide"]
  end

  def test_success_variant_renders_circle_check_icon
    render_inline(UI::Alert.new(variant: :success)) { "Success" }
    icons = page.all("i", visible: :all)
    assert_equal 1, icons.size
    assert_equal "circle-check", icons.first["data-lucide"]
  end

  def test_custom_icon_slot_overrides_default
    render_inline(UI::Alert.new(variant: :default)) do |alert|
      alert.with_icon(name: "badge-check")
      "Custom icon"
    end
    icons = page.all("i", visible: :all)
    assert_equal 1, icons.size
    assert_equal "badge-check", icons.first["data-lucide"]
  end

  def test_title_slot_renders
    render_inline(UI::Alert.new) do |alert|
      alert.with_title { "Heads up" }
    end
    assert_selector "[role='alert'] h5", text: "Heads up"
  end

  def test_description_slot_renders
    render_inline(UI::Alert.new) do |alert|
      alert.with_description { "Description text" }
    end
    assert_selector "[role='alert'] div", text: "Description text"
  end

  def test_title_and_description_together
    render_inline(UI::Alert.new) do |alert|
      alert.with_title { "Title" }
      alert.with_description { "Body" }
    end
    alert_el = page.find("[role='alert']")
    assert_equal "TitleBody", alert_el.text.gsub(/\s+/, "")
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::Alert.new(class: "bg-red-500")) { "Custom" }
    classes = page.find("[role='alert']")[:class].split
    refute_includes classes, "bg-background"
    assert_includes classes, "bg-red-500"
  end

  def test_description_renders_html_content
    render_inline(UI::Alert.new) do |alert|
      alert.with_description { "Click <a href='/docs'>here</a> for details".html_safe }
    end
    assert_selector "[role='alert'] a[href='/docs']", text: "here"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Alert.new(id: "my-alert", data: { test_id: "alert-x" })) { "x" }
    assert_selector "[role='alert']#my-alert[data-test-id='alert-x']"
  end

  def test_base_class_structure
    render_inline(UI::Alert.new) { "x" }
    classes = page.find("[role='alert']")[:class].split
    assert_includes classes, "rounded-md"
    assert_includes classes, "border"
    assert_includes classes, "p-4"
    # Layout switched from grid to flex (icon + content row).
    assert_includes classes, "flex"
    assert_includes classes, "items-start"
  end

  # Dismissible close button

  def test_dismissible_false_does_not_render_close_button
    render_inline(UI::Alert.new(dismissible: false)) { "Not dismissible" }
    refute_selector "[role='alert'] button"
  end

  def test_dismissible_true_renders_close_button
    render_inline(UI::Alert.new(dismissible: true)) { "Dismissible" }
    assert_selector "[role='alert'] button[aria-label='Close alert']"
  end

  def test_close_button_renders_x_icon
    render_inline(UI::Alert.new(dismissible: true)) { "Dismissible" }
    icons = page.all("[role='alert'] button i")
    assert_equal 1, icons.size
    assert_equal "x", icons.first["data-lucide"]
  end

  def test_close_button_has_dismiss_action
    render_inline(UI::Alert.new(dismissible: true)) { "Dismissible" }
    button = page.find("[role='alert'] button")
    assert_includes button["data-action"], "click->ui--alert#dismiss"
  end

  def test_close_button_is_positioned_at_top_right
    render_inline(UI::Alert.new(dismissible: true)) { "Dismissible" }
    button = page.find("[role='alert'] button")
    classes = button[:class].split
    assert_includes classes, "shrink-0"
    assert_includes classes, "-mr-1"
    assert_includes classes, "-mt-1"
  end

  def test_dismissible_alert_has_data_controller
    render_inline(UI::Alert.new(dismissible: true)) { "Dismissible" }
    alert = page.find("[role='alert']")
    assert_equal "ui--alert", alert["data-controller"]
  end

  def test_non_dismissible_alert_has_no_data_controller
    render_inline(UI::Alert.new(dismissible: false)) { "Not dismissible" }
    alert = page.find("[role='alert']")
    refute alert["data-controller"].present?
  end
end

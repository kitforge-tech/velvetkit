# frozen_string_literal: true

require "test_helper"

class UI::ToastTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def toast_el
    page.find("[data-slot='toast']")
  end

  def test_renders_container
    render_inline(UI::Toast.new(title: "Saved"))
    assert toast_el.present?
  end

  def test_fill_mode_forwards_prevents_a_flash_before_removal
    # tw-animate-css's animate-in/animate-out default to fill-mode: none, so
    # without this the element snaps back to fully visible right as the exit
    # animation ends, a flicker just before the controller removes it.
    render_inline(UI::Toast.new(title: "x"))
    assert_includes toast_el[:class].split, "fill-mode-forwards"
  end

  def test_surface_is_neutral_regardless_of_variant
    # Color lives on the icon only, not the surface — matching
    # Dialog/Sheet/Popover/Menu rather than Alert's tinted banner.
    %i[default success destructive warning info].each do |variant|
      render_inline(UI::Toast.new(variant: variant, title: "x"))
      classes = toast_el[:class].split
      assert_includes classes, "bg-popover"
      assert_includes classes, "text-popover-foreground"
      refute classes.any? { |c| c.match?(/^(bg|border)-(emerald|amber|sky|destructive)/) },
             "variant #{variant} colored something other than the icon"
    end
  end

  def test_default_variant_classes
    render_inline(UI::Toast.new(title: "x"))
    classes = toast_el[:class].split
    assert_includes classes, "[&>i]:text-muted-foreground"
  end

  def test_success_variant_classes
    render_inline(UI::Toast.new(variant: :success, title: "x"))
    classes = toast_el[:class].split
    assert_includes classes, "[&>i]:text-emerald-600"
  end

  def test_destructive_variant_classes
    render_inline(UI::Toast.new(variant: :destructive, title: "x"))
    classes = toast_el[:class].split
    assert_includes classes, "[&>i]:text-destructive"
  end

  def test_warning_variant_classes
    render_inline(UI::Toast.new(variant: :warning, title: "x"))
    classes = toast_el[:class].split
    assert_includes classes, "[&>i]:text-amber-600"
  end

  def test_info_variant_classes
    render_inline(UI::Toast.new(variant: :info, title: "x"))
    classes = toast_el[:class].split
    assert_includes classes, "[&>i]:text-sky-600"
  end

  def test_default_icon_per_variant
    { default: "info", success: "circle-check", destructive: "circle-alert", warning: "circle-alert", info: "info" }
      .each do |variant, icon|
      render_inline(UI::Toast.new(variant: variant, title: "x"))
      assert_selector "i[data-lucide='#{icon}']"
    end
  end

  def test_icon_false_suppresses_icon
    render_inline(UI::Toast.new(title: "x", icon: false))
    refute_selector "[data-slot='toast'] > i"
  end

  def test_icon_override
    render_inline(UI::Toast.new(title: "x", icon: "rocket"))
    assert_selector "[data-slot='toast'] > i[data-lucide='rocket']"
  end

  def test_title_renders
    render_inline(UI::Toast.new(title: "Saved"))
    assert_selector "[data-ui--toast-target='title']", text: "Saved"
  end

  def test_description_renders
    render_inline(UI::Toast.new(title: "Saved", description: "All set."))
    assert_selector "[data-ui--toast-target='description']", text: "All set."
  end

  def test_no_description_renders_no_description_node
    render_inline(UI::Toast.new(title: "Saved"))
    refute_selector "[data-ui--toast-target='description']"
  end

  def test_default_role_and_live_region
    render_inline(UI::Toast.new(title: "x"))
    assert_equal "status", toast_el["role"]
    assert_equal "polite", toast_el["aria-live"]
  end

  def test_destructive_role_and_live_region
    render_inline(UI::Toast.new(variant: :destructive, title: "x"))
    assert_equal "alert", toast_el["role"]
    assert_equal "assertive", toast_el["aria-live"]
  end

  def test_dismissible_by_default
    render_inline(UI::Toast.new(title: "x"))
    assert_selector "button[aria-label='Dismiss']"
  end

  def test_dismissible_false_hides_close_button
    render_inline(UI::Toast.new(title: "x", dismissible: false))
    refute_selector "button[aria-label='Dismiss']"
  end

  def test_close_button_wired_to_controller
    render_inline(UI::Toast.new(title: "x"))
    button = page.find("button[aria-label='Dismiss']")
    assert_includes button["data-action"], "click->ui--toast#dismiss"
  end

  def test_data_controller
    render_inline(UI::Toast.new(title: "x"))
    assert_equal "ui--toast", toast_el["data-controller"]
  end

  def test_default_duration_value_is_5_seconds_in_ms
    render_inline(UI::Toast.new(title: "x"))
    assert_equal "5000", toast_el["data-ui--toast-duration-value"]
  end

  def test_custom_duration_value_is_given_in_seconds
    render_inline(UI::Toast.new(title: "x", duration: 10))
    assert_equal "10000", toast_el["data-ui--toast-duration-value"]
  end

  def test_duration_accepts_an_active_support_duration
    render_inline(UI::Toast.new(title: "x", duration: 10.seconds))
    assert_equal "10000", toast_el["data-ui--toast-duration-value"]
  end

  def test_persistent_duration_value
    render_inline(UI::Toast.new(title: "x", duration: 0))
    assert_equal "0", toast_el["data-ui--toast-duration-value"]
  end

  def test_pause_and_resume_wired_on_hover
    render_inline(UI::Toast.new(title: "x"))
    action = toast_el["data-action"]
    assert_includes action, "mouseenter->ui--toast#pause"
    assert_includes action, "mouseleave->ui--toast#resume"
  end

  def test_initial_state_is_open
    render_inline(UI::Toast.new(title: "x"))
    assert_equal "open", toast_el["data-state"]
  end

  def test_renders_action_slot
    render_inline(UI::Toast.new(title: "x")) do |toast|
      toast.with_action { "Undo" }
    end
    assert_selector "[data-slot='toast'] div", text: "Undo"
  end

  def test_user_class_merge
    render_inline(UI::Toast.new(title: "x", class: "my-toast"))
    assert_includes toast_el[:class].split, "my-toast"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Toast.new(title: "x", id: "my-id", data: { test_id: "t" }))
    assert_selector "[data-slot='toast']#my-id[data-test-id='t']"
  end
end

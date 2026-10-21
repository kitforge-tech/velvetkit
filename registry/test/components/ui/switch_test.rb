# frozen_string_literal: true

require "test_helper"

class UI::SwitchTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  # ── Input element ────────────────────────────────────────────────────────────

  def test_renders_input_with_role_switch
    render_inline(UI::Switch.new(name: "notify"))
    input = page.find("input[type='checkbox']", visible: :all)
    assert_equal "switch", input[:role]
  end

  def test_input_is_visually_hidden_via_sr_only
    render_inline(UI::Switch.new(name: "notify"))
    classes = page.find("input[type='checkbox']", visible: :all)[:class].split
    assert_includes classes, "peer"
    assert_includes classes, "sr-only"
  end

  def test_input_does_not_carry_track_classes
    # Native browser tick painted whenever <input type=checkbox> stays in flow
    # — we keep it sr-only so no track/visual classes belong on the input.
    render_inline(UI::Switch.new(name: "notify"))
    classes = page.find("input[type='checkbox']", visible: :all)[:class].split
    refute_includes classes, "rounded-full"
    refute_includes classes, "bg-input"
    refute_includes classes, "appearance-none"
  end

  def test_checked_sets_checked_attribute
    render_inline(UI::Switch.new(name: "notify", checked: true))
    input = page.find("input[type='checkbox']", visible: :all)
    assert input["checked"].present?
  end

  def test_value_defaults_to_one
    render_inline(UI::Switch.new(name: "notify"))
    assert_equal "1", page.find("input[type='checkbox']", visible: :all)[:value]
  end

  def test_custom_value
    render_inline(UI::Switch.new(name: "notify", value: "on"))
    assert_equal "on", page.find("input[type='checkbox']", visible: :all)[:value]
  end

  def test_disabled_sets_disabled_attribute
    render_inline(UI::Switch.new(name: "notify", disabled: true))
    input = page.find("input[type='checkbox'][disabled]", visible: :all)
    assert input.disabled?
  end

  def test_required_sets_required_attribute
    render_inline(UI::Switch.new(name: "notify", required: true))
    assert_selector "input[type='checkbox'][required]", visible: :all
  end

  def test_data_attributes_passthrough
    render_inline(UI::Switch.new(name: "notify", data: { test_id: "sw-x" }))
    assert_selector "input[type='checkbox'][data-test-id='sw-x']", visible: :all
  end

  def test_auto_generated_id_when_label_present
    render_inline(UI::Switch.new(name: "notify", label: "Notify"))
    input = page.find("input[type='checkbox']", visible: :all)
    assert input[:id].present?
    assert input[:id].start_with?("ui-sw-")
  end

  # ── Track (sibling span) ─────────────────────────────────────────────────────

  def test_track_span_uses_peer_checked_for_state
    render_inline(UI::Switch.new(name: "notify"))
    track = page.all("span", visible: :all).find { |s|
      s[:class].to_s.include?("peer-checked:bg-primary")
    }
    assert track, "track span with peer-checked:bg-primary should exist"
    classes = track[:class].split
    assert_includes classes, "rounded-full"
    assert_includes classes, "bg-input"
    assert_includes classes, "peer-checked:bg-primary"
  end

  def test_track_span_has_focus_ring_via_peer_focus_visible
    render_inline(UI::Switch.new(name: "notify"))
    track = page.all("span", visible: :all).find { |s|
      s[:class].to_s.include?("peer-focus:ring-2")
    }
    assert track, "track span with peer-focus:ring-2 should exist"
    classes = track[:class].split
    assert_includes classes, "peer-focus:ring-primary"
    assert_includes classes, "peer-focus:ring-offset-1"
  end

  # ── Thumb ────────────────────────────────────────────────────────────────────

  def test_thumb_span_present_with_default_translate_class
    render_inline(UI::Switch.new(name: "notify"))
    thumb = page.all("span", visible: :all).find { |s|
      s[:class].to_s.include?("peer-checked:translate-x-")
    }
    assert thumb, "thumb span should exist"
    classes = thumb[:class].split
    assert_includes classes, "rounded-full"
    assert_includes classes, "bg-background"
    assert_includes classes, "peer-checked:translate-x-5"
  end

  # ── Sizes ────────────────────────────────────────────────────────────────────

  def test_size_sm_renders_smaller_track_and_thumb
    render_inline(UI::Switch.new(name: "notify", size: :sm))
    spans = page.all("span", visible: :all)
    root  = spans.find { |s| s[:class].to_s.include?("inline-flex shrink-0") }
    assert_includes root[:class].split, "w-8"
    assert_includes root[:class].split, "h-4"
    thumb = spans.find { |s| s[:class].to_s.include?("peer-checked:translate-x-") }
    assert_includes thumb[:class].split, "w-3"
    assert_includes thumb[:class].split, "h-3"
    assert_includes thumb[:class].split, "peer-checked:translate-x-4"
  end

  def test_size_lg_renders_larger_track_and_thumb
    render_inline(UI::Switch.new(name: "notify", size: :lg))
    spans = page.all("span", visible: :all)
    root  = spans.find { |s| s[:class].to_s.include?("inline-flex shrink-0") }
    assert_includes root[:class].split, "w-12"
    assert_includes root[:class].split, "h-6"
    thumb = spans.find { |s| s[:class].to_s.include?("peer-checked:translate-x-") }
    assert_includes thumb[:class].split, "w-5"
    assert_includes thumb[:class].split, "h-5"
    assert_includes thumb[:class].split, "peer-checked:translate-x-6"
  end

  # ── Wrapper / label ──────────────────────────────────────────────────────────

  def test_label_renders_label_element_with_for_id
    render_inline(UI::Switch.new(name: "notify", label: "Enable notifications"))
    label_el = page.find("label")
    input_el = page.find("input[type='checkbox']", visible: :all)
    assert_equal label_el["for"], input_el[:id]
    assert_match(/Enable notifications/, label_el.text)
  end

  def test_without_label_no_label_element
    render_inline(UI::Switch.new(name: "notify"))
    refute_selector "label"
  end

  def test_disabled_wrapper_dims
    render_inline(UI::Switch.new(name: "notify", disabled: true, label: "Notifications"))
    classes = page.find("label")[:class].split
    assert_includes classes, "cursor-not-allowed"
    assert_includes classes, "opacity-60"
  end

  def test_required_label_shows_styled_asterisk
    render_inline(UI::Switch.new(name: "notify", label: "Sub", required: true))
    asterisk = page.find("label span.text-destructive")
    assert_match(/\*/, asterisk.text)
    classes = asterisk[:class].split
    assert_includes classes, "text-destructive"
    assert_includes classes, "ml-0.5"
  end

  def test_non_required_label_has_no_destructive_span
    render_inline(UI::Switch.new(name: "notify", label: "Sub"))
    refute_selector "label span.text-destructive"
  end

  def test_label_text_renders_as_span_with_typography
    render_inline(UI::Switch.new(name: "notify", label: "Toggle"))
    span = page.find("label").all("span").find { |s| s.text.strip.start_with?("Toggle") }
    assert span, "label text span should exist"
    classes = span[:class].split
    assert_includes classes, "text-sm"
    assert_includes classes, "leading-none"
  end

  # ── User-class merge ────────────────────────────────────────────────────────

  def test_user_class_lands_on_track_not_input
    render_inline(UI::Switch.new(name: "notify", class: "ring-orange-500"))
    track = page.all("span", visible: :all).find { |s|
      s[:class].to_s.include?("peer-checked:bg-primary")
    }
    assert_includes track[:class].split, "ring-orange-500"
    input_classes = page.find("input[type='checkbox']", visible: :all)[:class].split
    refute_includes input_classes, "ring-orange-500"
  end
end

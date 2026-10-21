# frozen_string_literal: true

require "test_helper"

class UI::ButtonTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_default_variant_and_size
    render_inline(UI::Button.new) { "Save" }
    btn = page.find("button")
    assert_equal "button", btn[:type]
    assert_includes btn[:class], "bg-primary"
    assert_includes btn[:class], "text-primary-foreground"
    assert_includes btn[:class], "h-9"
    assert_equal "Save", btn.text.strip
  end

  def test_renders_destructive_variant
    render_inline(UI::Button.new(variant: :destructive)) { "Delete" }
    btn = page.find("button")
    classes = btn[:class].split
    assert_includes classes, "bg-destructive"
    refute_includes classes, "bg-primary"
    # destructive variant overrides the default focus ring color
    assert_includes classes, "focus:ring-destructive"
    refute_includes classes, "focus:ring-primary"
  end

  def test_renders_outline_variant
    render_inline(UI::Button.new(variant: :outline)) { "Cancel" }
    btn = page.find("button")
    assert_includes btn[:class], "border-input"
    assert_includes btn[:class], "bg-background"
  end

  def test_renders_secondary_variant
    render_inline(UI::Button.new(variant: :secondary)) { "Secondary" }
    assert_selector "button.bg-secondary", text: "Secondary"
  end

  def test_renders_ghost_variant
    render_inline(UI::Button.new(variant: :ghost)) { "Ghost" }
    btn = page.find("button")
    assert_includes btn[:class], "hover:bg-accent"
    refute_includes btn[:class], "bg-primary"
  end

  def test_renders_link_variant
    render_inline(UI::Button.new(variant: :link)) { "Link" }
    btn = page.find("button")
    assert_includes btn[:class], "text-primary"
    assert_includes btn[:class], "underline-offset-4"
  end

  def test_size_sm
    render_inline(UI::Button.new(size: :sm)) { "Small" }
    assert_selector "button.h-8", text: "Small"
  end

  def test_size_lg
    render_inline(UI::Button.new(size: :lg)) { "Large" }
    assert_selector "button.h-10", text: "Large"
  end

  def test_size_icon
    render_inline(UI::Button.new(size: :icon)) { "" }
    btn = page.find("button")
    assert_includes btn[:class], "h-9"
    assert_includes btn[:class], "w-9"
  end

  def test_size_icon_sm
    render_inline(UI::Button.new(size: :icon_sm)) { "" }
    btn = page.find("button")
    classes = btn[:class].split
    assert_includes classes, "h-7"
    assert_includes classes, "w-7"
  end

  def test_full_width_adds_w_full
    render_inline(UI::Button.new(full_width: true)) { "Wide" }
    assert_selector "button.w-full"
  end

  def test_loading_state_marks_cursor
    render_inline(UI::Button.new(loading: true)) { "Loading" }
    btn = page.find("button")
    assert_includes btn[:class].split, "disabled:cursor-not-allowed"
  end

  def test_loading_disables_the_button
    render_inline(UI::Button.new(loading: true)) { "Loading" }
    btn = page.find("button[disabled]")
    assert btn.disabled?, "button should be disabled while loading"
  end

  def test_disabled_param_disables_the_button
    render_inline(UI::Button.new(disabled: true)) { "Off" }
    btn = page.find("button[disabled]")
    assert btn.disabled?, "button should be disabled when disabled: true"
  end

  def test_disabled_emits_disabled_grayscale_classes
    render_inline(UI::Button.new(disabled: true)) { "Off" }
    classes = page.find("button[disabled]")[:class].split
    refute_includes classes, "disabled:opacity-50"
    assert_includes classes, "disabled:bg-muted!"
    assert_includes classes, "disabled:text-muted-foreground!"
    assert_includes classes, "disabled:pointer-events-none"
    assert_includes classes, "disabled:cursor-not-allowed"
  end

  def test_disabled_outline_variant_uses_muted_border
    render_inline(UI::Button.new(variant: :outline, disabled: true)) { "Off" }
    classes = page.find("button[disabled]")[:class].split
    assert_includes classes, "disabled:bg-muted!"
    assert_includes classes, "disabled:text-muted-foreground!"
    assert_includes classes, "disabled:border-input!"
  end

  def test_disabled_ghost_variant_keeps_transparent_bg
    render_inline(UI::Button.new(variant: :ghost, disabled: true)) { "Off" }
    classes = page.find("button[disabled]")[:class].split
    assert_includes classes, "disabled:bg-transparent!"
    assert_includes classes, "disabled:text-muted-foreground!"
  end

  def test_disabled_link_variant_drops_underline
    render_inline(UI::Button.new(variant: :link, disabled: true)) { "Off" }
    classes = page.find("button[disabled]")[:class].split
    assert_includes classes, "disabled:text-muted-foreground!"
    assert_includes classes, "disabled:no-underline!"
  end

  def test_default_button_is_not_disabled
    render_inline(UI::Button.new) { "Active" }
    btn = page.find("button")
    refute btn.disabled?, "button should not be disabled by default"
  end

  def test_disabled_and_loading_both_disable
    render_inline(UI::Button.new(disabled: true, loading: true)) { "Both" }
    btn = page.find("button[disabled]")
    assert btn.disabled?
  end

  def test_type_attribute_can_be_overridden
    render_inline(UI::Button.new(type: :submit)) { "Submit" }
    assert_selector "button[type='submit']", text: "Submit"
  end

  def test_user_class_overrides_variant_default
    render_inline(UI::Button.new(class: "bg-red-500")) { "Custom" }
    btn = page.find("button")
    classes = btn[:class].split
    refute_includes classes, "bg-primary"
    assert_includes classes, "bg-red-500"
    assert_includes classes, "text-primary-foreground"
  end

  def test_arbitrary_html_attributes_pass_through
    render_inline(UI::Button.new(data: { test_id: "save-btn" }, id: "primary-cta")) { "Save" }
    assert_selector "button#primary-cta[data-test-id='save-btn']", text: "Save"
  end

  def test_as_child_param_accepted_without_error
    assert_nothing_raised do
      render_inline(UI::Button.new(as_child: true)) { "Future" }
    end
    assert_selector "button", text: "Future"
  end

  # ── Icon slots ──────────────────────────────────────────────────────────────

  def test_leading_icon_renders_before_content
    render_inline(UI::Button.new) do |btn|
      btn.with_leading_icon(name: "arrow-right")
      "Continue"
    end
    btn = page.find("button")
    icons = btn.all("i", visible: :all)
    assert_equal 1, icons.size
    assert_equal "arrow-right", icons.first["data-lucide"]
    # icon precedes text in DOM order
    assert_match(/<i[^>]*data-lucide="arrow-right".*Continue/m, btn.native.to_html)
  end

  def test_trailing_icon_renders_after_content
    render_inline(UI::Button.new) do |btn|
      btn.with_trailing_icon(name: "arrow-right")
      "Next"
    end
    btn = page.find("button")
    assert_match(/Next.*<i[^>]*data-lucide="arrow-right"/m, btn.native.to_html)
  end

  def test_both_leading_and_trailing_icons
    render_inline(UI::Button.new) do |btn|
      btn.with_leading_icon(name: "lock")
      btn.with_trailing_icon(name: "arrow-right")
      "Sign in"
    end
    btn = page.find("button")
    icons = btn.all("i", visible: :all).map { |i| i["data-lucide"] }
    assert_equal [ "lock", "arrow-right" ], icons
  end

  def test_icon_only_button_renders_icon_without_text_slot
    render_inline(UI::Button.new(size: :icon)) do |btn|
      btn.with_leading_icon(name: "menu")
    end
    btn = page.find("button")
    classes = btn[:class].split
    assert_includes classes, "h-9"
    assert_includes classes, "w-9"
    assert_equal "menu", btn.find("i", visible: :all)["data-lucide"]
  end

  def test_loading_replaces_leading_icon_with_animated_loader
    render_inline(UI::Button.new(loading: true)) do |btn|
      btn.with_leading_icon(name: "lock")
      "Saving"
    end
    btn = page.find("button")
    icons = btn.all("i", visible: :all)
    assert_equal 1, icons.size
    loader = icons.first
    assert_equal "loader", loader["data-lucide"]
    assert_includes loader[:class].split, "animate-spin"
  end

  def test_loading_hides_trailing_icon
    render_inline(UI::Button.new(loading: true)) do |btn|
      btn.with_trailing_icon(name: "arrow-right")
      "Saving"
    end
    btn = page.find("button")
    # only the loader is rendered; trailing icon dropped
    icons = btn.all("i", visible: :all).map { |i| i["data-lucide"] }
    assert_equal [ "loader" ], icons
  end

  def test_icon_slot_auto_sizes_to_button_size_sm
    render_inline(UI::Button.new(size: :sm)) do |btn|
      btn.with_leading_icon(name: "lock")
      "Auth"
    end
    icon = page.find("button i", visible: :all)
    classes = icon[:class].split
    assert_includes classes, "w-3"
    assert_includes classes, "h-3"
  end

  def test_icon_slot_auto_sizes_to_button_size_lg
    render_inline(UI::Button.new(size: :lg)) do |btn|
      btn.with_leading_icon(name: "lock")
      "Auth"
    end
    icon = page.find("button i", visible: :all)
    classes = icon[:class].split
    assert_includes classes, "w-5"
    assert_includes classes, "h-5"
  end

  def test_icon_slot_explicit_size_overrides_auto
    render_inline(UI::Button.new(size: :sm)) do |btn|
      btn.with_leading_icon(name: "lock", size: :xl)
      "Big"
    end
    icon = page.find("button i", visible: :all)
    classes = icon[:class].split
    assert_includes classes, "w-8"
    assert_includes classes, "h-8"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::ThemeToggleTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_wires_the_theme_controller
    render_inline(UI::ThemeToggle.new)
    assert_selector "[data-controller='ui--theme']"
  end

  def test_trigger_has_an_accessible_name
    render_inline(UI::ThemeToggle.new)
    assert_equal "Change theme", page.find("button[aria-haspopup]")[:"aria-label"]
  end

  def test_custom_label
    render_inline(UI::ThemeToggle.new(label: "Appearance"))
    assert_equal "Appearance", page.find("button[aria-haspopup]")[:"aria-label"]
  end

  def test_offers_all_three_preferences
    render_inline(UI::ThemeToggle.new)
    themes = page.all("[data-ui--theme-target='option']", visible: :all).map { |o| o[:"data-theme"] }
    assert_equal %w[light dark system], themes
  end

  def test_options_wire_the_select_action
    render_inline(UI::ThemeToggle.new)
    page.all("[data-ui--theme-target='option']", visible: :all).each do |option|
      assert_includes option[:"data-action"], "ui--theme#select"
    end
  end

  # aria-checked is only valid on a radio/checkbox role, so the options must
  # not fall back to UI::Menu::Item's default role="menuitem".
  def test_options_use_the_radio_role_for_aria_checked
    render_inline(UI::ThemeToggle.new)
    options = page.all("[data-ui--theme-target='option']", visible: :all)
    assert_equal 3, options.size
    options.each do |option|
      assert_equal "menuitemradio", option[:role]
      assert_equal "false", option[:"aria-checked"]
    end
  end

  # lucide swaps each <i data-lucide> for an <svg> on first render, so the
  # element is gone afterwards and the icon cannot be changed by attribute.
  # All three are rendered and shown by the preference on <html data-theme>:
  # a monitor while following the system (the default, and before any script
  # runs), so "system" is visible rather than looking like light or dark.
  def test_trigger_icon_follows_the_preference_with_system_by_default
    render_inline(UI::ThemeToggle.new)
    trigger = page.find("button[aria-haspopup]")
    icon = ->(name) { trigger.find("i[data-lucide='#{name}']", visible: :all)[:class].split }
    assert_includes icon.("sun"), "in-data-[theme=light]:block"
    assert_includes icon.("moon"), "in-data-[theme=dark]:block"
    monitor = icon.("monitor")
    assert_includes monitor, "block"
    assert_includes monitor, "in-data-[theme=light]:hidden"
    assert_includes monitor, "in-data-[theme=dark]:hidden"
  end

  def test_html_attrs_passthrough
    render_inline(UI::ThemeToggle.new(id: "theme", data: { test_id: "tt" }))
    assert_selector "#theme[data-test-id='tt']"
  end

  # The checked option needs a persistent background, not just a focus ring —
  # otherwise nothing shows which theme is active once focus moves.
  def test_options_carry_the_checked_state_styling
    render_inline(UI::ThemeToggle.new)
    option = page.all("[data-ui--theme-target='option']", visible: :all).first
    classes = option[:class].split
    assert_includes classes, "aria-checked:bg-accent"
    assert_includes classes, "aria-checked:font-medium"
  end

  def test_each_option_has_a_check_indicator_shown_only_when_checked
    render_inline(UI::ThemeToggle.new)
    page.all("[data-ui--theme-target='option']", visible: :all).each do |option|
      check = option.find("i[data-lucide='check']", visible: :all)
      assert_includes check[:class].split, "hidden"
      assert_includes check[:class].split, "group-aria-checked:block"
    end
  end
end

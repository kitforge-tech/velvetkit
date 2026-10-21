# frozen_string_literal: true

require "test_helper"

class UI::Tabs::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_trigger(variant: :line, size: :default, disabled: false)
    render_inline(UI::Tabs.new(default_value: "a", variant: variant, size: size)) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a", disabled: disabled) { "A" }
        list.with_trigger(value: "b") { "B" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
      tabs.with_panel(value: "b") { "panel-b" }
    end
  end

  def test_renders_button_with_role_tab
    render_trigger
    btn = page.find("[role='tab'][data-value='a']")
    assert_equal "button", btn.tag_name
    assert_equal "tab", btn[:role]
  end

  def test_type_button
    render_trigger
    btn = page.find("[role='tab'][data-value='a']")
    assert_equal "button", btn[:type]
  end

  def test_aria_selected_true_when_active
    render_trigger
    active = page.find("[role='tab'][aria-selected='true']")
    assert_equal "a", active["data-value"]
  end

  def test_aria_selected_false_when_inactive
    render_trigger
    inactive = page.find("[role='tab'][aria-selected='false']")
    assert_equal "b", inactive["data-value"]
  end

  def test_aria_controls_matches_panel_id
    render_trigger
    trigger = page.find("[role='tab'][data-value='a']")
    panel = page.find("[role='tabpanel'][data-value='a']")
    assert_equal panel[:id], trigger["aria-controls"]
  end

  def test_tabindex_zero_when_active
    render_trigger
    active = page.find("[role='tab'][tabindex='0']")
    assert_equal "a", active["data-value"]
  end

  def test_tabindex_minus_one_when_inactive
    render_trigger
    inactive = page.find("[role='tab'][tabindex='-1']")
    assert_equal "b", inactive["data-value"]
  end

  def test_data_state_active_when_active
    render_trigger
    active = page.find("[role='tab'][data-state='active']")
    assert_equal "a", active["data-value"]
  end

  def test_data_state_inactive_when_inactive
    render_trigger
    inactive = page.find("[role='tab'][data-state='inactive']")
    assert_equal "b", inactive["data-value"]
  end

  def test_data_action_includes_click_and_keydown
    render_trigger
    btn = page.find("[role='tab'][data-value='a']")
    assert_includes btn["data-action"], "click->ui--tabs#activate"
    assert_includes btn["data-action"], "keydown->ui--tabs#keydown"
  end

  def test_data_ui_tabs_target_trigger
    render_trigger
    btn = page.find("[role='tab'][data-value='a']")
    assert_equal "trigger", btn["data-ui--tabs-target"]
  end

  def test_disabled_sets_disabled_attribute
    render_trigger(disabled: true)
    btn = page.find("[role='tab'][disabled]")
    assert btn.disabled?
    assert_equal "a", btn["data-value"]
  end

  def test_leading_icon_slot
    render_inline(UI::Tabs.new(default_value: "a")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") do |trigger|
          trigger.with_leading_icon(name: "user")
          "Account"
        end
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    icon = page.find("[role='tab'][data-value='a'] i", visible: :all)
    assert_equal "user", icon["data-lucide"]
  end

  def test_line_variant_size_sm
    render_trigger(variant: :line, size: :sm)
    btn = page.find("[role='tab'][data-value='a']")
    classes = btn[:class].split
    assert_includes classes, "h-8"
    assert_includes classes, "text-xs"
  end

  def test_line_variant_size_lg
    render_trigger(variant: :line, size: :lg)
    btn = page.find("[role='tab'][data-value='a']")
    classes = btn[:class].split
    assert_includes classes, "h-11"
    assert_includes classes, "text-base"
  end

  def test_pill_variant_size_default
    render_trigger(variant: :pill, size: :default)
    btn = page.find("[role='tab'][data-value='a']")
    classes = btn[:class].split
    assert_includes classes, "h-8"
    assert_includes classes, "text-sm"
  end

  def test_solid_variant_size_default
    render_trigger(variant: :solid, size: :default)
    btn = page.find("[role='tab'][data-value='a']")
    classes = btn[:class].split
    assert_includes classes, "h-10"
    assert_includes classes, "text-sm"
  end

  def test_user_class_merge
    render_inline(UI::Tabs.new(default_value: "a")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a", class: "my-trigger") { "A" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    classes = page.find("[role='tab']")[:class].split
    assert_includes classes, "my-trigger"
  end

  def test_auto_generated_id
    render_trigger
    btn = page.find("[role='tab'][data-value='a']")
    assert btn[:id].present?
    assert btn[:id].start_with?("ui-tab-")
  end
end

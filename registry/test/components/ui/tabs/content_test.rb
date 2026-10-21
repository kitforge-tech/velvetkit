# frozen_string_literal: true

require "test_helper"

class UI::Tabs::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_content(default_value: "a")
    render_inline(UI::Tabs.new(default_value: default_value)) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
        list.with_trigger(value: "b") { "B" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
      tabs.with_panel(value: "b") { "panel-b" }
    end
  end

  def test_renders_tabpanel_role
    render_content
    assert_selector "[role='tabpanel']"
  end

  def test_aria_labelledby_matches_trigger_id
    render_content
    panel = page.find("[role='tabpanel'][data-value='a']")
    trigger = page.find("[role='tab'][data-value='a']")
    assert_equal trigger[:id], panel["aria-labelledby"]
  end

  def test_tabindex_zero
    render_content
    panel = page.find("[role='tabpanel']")
    assert_equal "0", panel[:tabindex]
  end

  def test_data_state_active_when_active
    render_content(default_value: "a")
    panel = page.find("[role='tabpanel'][data-state='active']")
    assert_equal "a", panel["data-value"]
  end

  def test_data_state_inactive_when_inactive
    render_content(default_value: "a")
    panel = page.find("[role='tabpanel'][data-state='inactive']", visible: :all)
    assert_equal "b", panel["data-value"]
  end

  def test_data_ui_tabs_target_panel
    render_content
    panel = page.find("[role='tabpanel']")
    assert_equal "panel", panel["data-ui--tabs-target"]
  end

  def test_hidden_when_inactive
    render_content(default_value: "a")
    panel = page.find("[role='tabpanel'][data-value='b']", visible: :all)
    assert panel[:hidden].present?
  end

  def test_not_hidden_when_active
    render_content(default_value: "a")
    panel = page.find("[role='tabpanel'][data-value='a']")
    refute panel[:hidden].present?
  end

  def test_user_class_merge
    render_inline(UI::Tabs.new(default_value: "a")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
      end
      tabs.with_panel(value: "a", class: "my-panel") { "panel-a" }
    end
    classes = page.find("[role='tabpanel']")[:class].split
    assert_includes classes, "my-panel"
    assert_includes classes, "mt-2"
  end

  def test_auto_generated_panel_id
    render_content
    panel = page.find("[role='tabpanel']")
    assert panel[:id].present?
    assert panel[:id].start_with?("ui-panel-")
  end

  def test_panel_id_matches_trigger_aria_controls
    render_content
    panel = page.find("[role='tabpanel'][data-value='a']")
    trigger = page.find("[role='tab'][data-value='a']")
    assert_equal panel[:id], trigger["aria-controls"]
  end
end

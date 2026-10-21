# frozen_string_literal: true

require "test_helper"

class UI::TabsTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_tabs(default_value: "a", variant: :line)
    render_inline(UI::Tabs.new(default_value: default_value, variant: variant)) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
        list.with_trigger(value: "b") { "B" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
      tabs.with_panel(value: "b") { "panel-b" }
    end
  end

  def test_root_carries_controller
    render_tabs
    root = page.find("[data-controller~='ui--tabs']")
    assert_equal "a", root["data-ui--tabs-active-value"]
  end

  def test_default_value_selects_active_tab
    render_tabs(default_value: "b")
    root = page.find("[data-controller~='ui--tabs']")
    assert_equal "b", root["data-ui--tabs-active-value"]
  end

  def test_inactive_panel_is_hidden
    render_tabs(default_value: "a")
    assert_selector "[role='tabpanel'][data-value='b'][hidden]", visible: :all
    assert_no_selector "[role='tabpanel'][data-value='a'][hidden]", visible: :all
  end

  def test_active_panel_not_hidden
    render_tabs(default_value: "a")
    panel = page.find("[role='tabpanel'][data-value='a']")
    refute panel[:hidden].present?
  end

  def test_root_has_auto_generated_id
    render_tabs
    root = page.find("[data-controller~='ui--tabs']")
    assert root[:id].present?
    assert root[:id].start_with?("ui-tabs-")
  end

  def test_custom_id_preserved
    render_inline(UI::Tabs.new(default_value: "a", id: "my-tabs")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    assert_selector "[data-controller~='ui--tabs']#my-tabs"
  end

  def test_user_class_merge
    render_inline(UI::Tabs.new(default_value: "a", class: "my-custom-class")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    classes = page.find("[data-controller~='ui--tabs']")[:class].split
    assert_includes classes, "my-custom-class"
    assert_includes classes, "w-full"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Tabs.new(default_value: "a", data: { test_id: "tabs-x" })) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    assert_selector "[data-controller~='ui--tabs'][data-test-id='tabs-x']"
  end

  def test_panels_rendered_at_root_level
    render_tabs
    panels = page.all("[role='tabpanel']", visible: :all)
    assert_equal 2, panels.size
  end
end

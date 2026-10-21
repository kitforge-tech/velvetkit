# frozen_string_literal: true

require "test_helper"

class UI::Menu::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger text" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    assert_text "Trigger text"
  end

  def test_has_aria_attributes
    render_inline(UI::Menu.new(id: "test-id")) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert_equal "true", trigger[:"aria-haspopup"]
    assert_equal "false", trigger[:"aria-expanded"]
    assert trigger[:"aria-controls"].start_with?("ui-menu-content-")
  end

  def test_has_data_target
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    assert_selector "button[data-ui--menu-target='trigger']"
  end

  def test_has_toggle_action
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert trigger[:"data-action"].include?("click->ui--menu#toggle")
  end

  def test_has_keydown_action
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert trigger[:"data-action"].include?("keydown->ui--menu#triggerKeydown")
  end

  def test_renders_as_button_with_default_variant
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert trigger[:class].include?("border")
    assert trigger[:class].include?("bg-background")
  end

  def test_custom_variant
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger(variant: :default) { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert trigger[:class].include?("bg-primary")
  end

  def test_custom_size
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger(size: :sm) { "Small" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']", text: "Small")
    assert trigger[:class].include?("h-8")
    assert trigger[:class].include?("text-xs")
  end

  def test_custom_class_merge
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger(class: "custom-trigger") { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    trigger = page.find("button[data-ui--menu-target='trigger']")
    assert_includes trigger[:class].split, "custom-trigger"
  end
end

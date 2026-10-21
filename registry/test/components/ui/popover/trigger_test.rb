# frozen_string_literal: true

require "test_helper"

class UI::Popover::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger text" }
      popover.with_content { "Content" }
    end
    assert_text "Trigger text"
  end

  def test_has_aria_attributes
    render_inline(UI::Popover.new(id: "test-id")) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']")
    assert_equal "true", trigger[:"aria-haspopup"]
    assert_equal "false", trigger[:"aria-expanded"]
    assert_equal "ui-popover-content-test-id", trigger[:"aria-controls"]
  end

  def test_has_data_target
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    assert_selector "button[data-ui--popover-target='trigger']"
  end

  def test_has_toggle_action
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']")
    assert trigger[:"data-action"].include?("click->ui--popover#toggle")
  end

  def test_renders_as_button_with_default_variant
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']")
    assert trigger[:class].include?("border")
    assert trigger[:class].include?("bg-background")
  end

  def test_custom_variant
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger(variant: :default) { "Trigger" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']")
    assert trigger[:class].include?("bg-primary")
    assert trigger[:class].include?("text-primary-foreground")
  end

  def test_custom_size
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger(size: :sm) { "Small" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']", text: "Small")
    assert trigger[:class].include?("h-8")
    assert trigger[:class].include?("text-xs")
  end

  def test_custom_class_merge
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger(class: "custom-trigger") { "Trigger" }
      popover.with_content { "Content" }
    end
    trigger = page.find("button[data-ui--popover-target='trigger']")
    assert_includes trigger[:class].split, "custom-trigger"
  end
end

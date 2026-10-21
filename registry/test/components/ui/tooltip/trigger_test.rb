# frozen_string_literal: true

require "test_helper"

class UI::Tooltip::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger text" }
      tooltip.with_content { "Content" }
    end
    assert_text "Trigger text"
  end

  def test_has_aria_describedby
    render_inline(UI::Tooltip.new(id: "test-id")) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    trigger = page.find("[data-ui--tooltip-target='trigger']")
    assert_equal "ui-tooltip-content-test-id", trigger[:"aria-describedby"]
  end

  def test_has_data_target
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    assert_selector "[data-ui--tooltip-target='trigger']"
  end

  def test_has_interaction_actions
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    trigger = page.find("[data-ui--tooltip-target='trigger']")
    assert trigger[:"data-action"].include?("mouseenter->ui--tooltip#show")
    assert trigger[:"data-action"].include?("mouseleave->ui--tooltip#hide")
  end

  def test_custom_class_merge
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger(class: "custom-trigger") { "Trigger" }
      tooltip.with_content { "Content" }
    end
    trigger = page.find("[data-ui--tooltip-target='trigger']")
    assert_includes trigger[:class].split, "custom-trigger"
  end
end

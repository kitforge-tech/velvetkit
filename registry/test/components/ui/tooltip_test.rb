# frozen_string_literal: true

require "test_helper"

class UI::TooltipTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_tooltip
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Hover me" }
      tooltip.with_content { "Tooltip text" }
    end
  end

  def test_root_renders_trigger_and_content
    result = render_tooltip
    assert_text "Hover me"
    # Tooltip content is hidden by default, check it's in the HTML
    assert result.to_html.include?("Tooltip text")
  end

  def test_trigger_has_aria_describedby
    render_tooltip
    trigger = page.find("[data-ui--tooltip-target='trigger']")
    assert trigger[:"aria-describedby"].present?
    assert trigger[:"aria-describedby"].start_with?("ui-tooltip-content-")
  end

  def test_trigger_has_interaction_actions
    render_tooltip
    trigger = page.find("[data-ui--tooltip-target='trigger']")
    assert trigger[:"data-action"].include?("mouseenter->ui--tooltip#show")
    assert trigger[:"data-action"].include?("mouseleave->ui--tooltip#hide")
    assert trigger[:"data-action"].include?("focus->ui--tooltip#show")
    assert trigger[:"data-action"].include?("blur->ui--tooltip#hide")
  end

  def test_content_has_role_tooltip
    render_tooltip
    assert_selector "[role='tooltip']", visible: false
  end

  def test_content_is_initially_hidden
    render_tooltip
    content = page.find("[role='tooltip']", visible: false)
    assert content[:hidden].present?
  end

  def test_content_has_data_targets
    render_tooltip
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "content", content[:"data-ui--tooltip-target"]
  end

  def test_default_side_is_top
    render_tooltip
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_side
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Hover me" }
      tooltip.with_content(side: :bottom) { "Tooltip text" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "bottom", content[:"data-side"]
  end

  def test_custom_id_preserved
    render_inline(UI::Tooltip.new(id: "my-tooltip")) do |tooltip|
      tooltip.with_trigger { "Hover me" }
      tooltip.with_content { "Tooltip text" }
    end
    assert_selector "#my-tooltip"
  end

  def test_user_class_merge
    render_inline(UI::Tooltip.new(class: "my-custom-class")) do |tooltip|
      tooltip.with_trigger { "Hover me" }
      tooltip.with_content { "Tooltip text" }
    end
    root = page.find("[data-controller='ui--tooltip']")
    classes = root[:class].split
    assert_includes classes, "my-custom-class"
    assert_includes classes, "inline-block"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Tooltip.new(data: { test_id: "tooltip-x" })) do |tooltip|
      tooltip.with_trigger { "Hover me" }
      tooltip.with_content { "Tooltip text" }
    end
    assert_selector "[data-controller='ui--tooltip'][data-test-id='tooltip-x']"
  end
end

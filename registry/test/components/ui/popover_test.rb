# frozen_string_literal: true

require "test_helper"

class UI::PopoverTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_popover
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Open Popover" }
      popover.with_content { "Popover content" }
    end
  end

  def test_root_renders_trigger_and_content
    result = render_popover
    assert_text "Open Popover"
    assert result.to_html.include?("Popover content")
  end

  def test_trigger_has_aria_attributes
    render_popover
    trigger = page.find("[data-ui--popover-target='trigger']")
    assert_equal "true", trigger[:"aria-haspopup"]
    assert_equal "false", trigger[:"aria-expanded"]
    assert trigger[:"aria-controls"].present?
    assert trigger[:"aria-controls"].start_with?("ui-popover-content-")
  end

  def test_trigger_has_click_action
    render_popover
    trigger = page.find("[data-ui--popover-target='trigger']")
    assert trigger[:"data-action"].include?("click->ui--popover#toggle")
  end

  def test_content_has_role_dialog
    render_popover
    assert_selector "[role='dialog']", visible: false
  end

  def test_content_is_initially_hidden
    render_popover
    content = page.find("[role='dialog']", visible: false)
    assert content[:hidden].present?
  end

  def test_content_has_data_targets
    render_popover
    content = page.find("[role='dialog']", visible: false)
    assert_equal "content", content[:"data-ui--popover-target"]
  end

  def test_default_side_is_top
    render_popover
    content = page.find("[role='dialog']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_side
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Open" }
      popover.with_content(side: :bottom) { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "bottom", content[:"data-side"]
  end

  def test_default_width_280px
    render_popover
    content = page.find("[role='dialog']", visible: false)
    assert content[:class].include?("w-72") # 72 * 4px = 288px (Tailwind w-72 is 18rem/288px)
  end

  def test_custom_id_preserved
    render_inline(UI::Popover.new(id: "my-popover")) do |popover|
      popover.with_trigger { "Open" }
      popover.with_content { "Content" }
    end
    assert_selector "#my-popover"
  end

  def test_user_class_merge
    render_inline(UI::Popover.new(class: "my-custom-class")) do |popover|
      popover.with_trigger { "Open" }
      popover.with_content { "Content" }
    end
    root = page.find("[data-controller='ui--popover']")
    classes = root[:class].split
    assert_includes classes, "my-custom-class"
    assert_includes classes, "inline-block"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Popover.new(data: { test_id: "popover-x" })) do |popover|
      popover.with_trigger { "Open" }
      popover.with_content { "Content" }
    end
    assert_selector "[data-controller='ui--popover'][data-test-id='popover-x']"
  end
end

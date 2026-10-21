# frozen_string_literal: true

require "test_helper"

class UI::Popover::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    result = render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Popover content" }
    end
    assert result.to_html.include?("Popover content")
  end

  def test_has_role_dialog
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    assert_selector "[role='dialog']", visible: false
  end

  def test_has_aria_modal_false
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "false", content[:"aria-modal"]
  end

  def test_is_initially_hidden
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert content[:hidden].present?
  end

  def test_has_data_target
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "content", content[:"data-ui--popover-target"]
  end

  def test_default_side_top
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_side
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(side: :right) { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "right", content[:"data-side"]
  end

  def test_custom_align
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(align: :end) { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "end", content[:"data-align"]
  end

  def test_has_animation_classes
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert content[:class].include?("animate-in")
    assert content[:class].include?("fade-in-0")
  end

  def test_has_arrow_element
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    assert_selector "[data-ui--popover-target='arrow']", visible: false
  end

  def test_has_default_width
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert content[:class].include?("w-72")
  end

  def test_has_popover_styling
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert content[:class].include?("bg-popover")
    assert content[:class].include?("text-popover-foreground")
    assert content[:class].include?("rounded-md")
    assert content[:class].include?("shadow-md")
  end

  def test_custom_class_merge
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(class: "custom-content") { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    assert_includes content[:class].split, "custom-content"
  end

  def test_renders_title
    result = render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content do |content|
        content.with_title { "My Title" }
        "Body content"
      end
    end
    assert result.to_html.include?("My Title")
  end

  def test_title_has_heading_classes
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content do |content|
        content.with_title { "My Title" }
        "Body"
      end
    end
    title = page.find("h3", text: "My Title", visible: false)
    assert title[:class].include?("font-semibold")
  end

  def test_title_sets_aria_labelledby
    render_inline(UI::Popover.new(id: "test-popover")) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content do |content|
        content.with_title { "My Title" }
        "Body"
      end
    end
    content = page.find("[role='dialog']", visible: false)
    assert_equal "ui-popover-title-test-popover", content[:"aria-labelledby"]
  end

  def test_show_close_button
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(show_close: true) { "Content" }
    end
    close_button = page.find("button[aria-label='Close']", visible: false)
    assert close_button.present?
  end

  def test_close_button_has_action
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(show_close: true) { "Content" }
    end
    close_button = page.find("button[aria-label='Close']", visible: false)
    assert close_button[:"data-action"].include?("click->ui--popover#close")
  end

  def test_close_button_uses_ghost_variant
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(show_close: true) { "Content" }
    end
    close_button = page.find("button[aria-label='Close']", visible: false)
    assert close_button[:class].include?("hover:bg-accent")
  end

  def test_arrow_has_data_side_attribute
    # Arrow has data-side attribute that Floating UI can update dynamically
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(side: :top) { "Content" }
    end
    arrow = page.find("[data-ui--popover-target='arrow']", visible: false)
    assert_equal "top", arrow[:"data-side"]
  end

  def test_arrow_has_base_border_classes
    # Arrow has base border-t border-l (points down) with conditional overrides
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content { "Content" }
    end
    arrow = page.find("[data-ui--popover-target='arrow']", visible: false)
    classes = arrow[:class]
    # Base classes
    assert classes.include?("border-t"), "Expected border-t in arrow classes"
    assert classes.include?("border-l"), "Expected border-l in arrow classes"
    # Conditional override classes for all sides are present
    assert classes.include?("data-[side=bottom]:border-t-0"), "Expected data-[side=bottom]:border-t-0"
    assert classes.include?("data-[side=bottom]:border-l-0"), "Expected data-[side=bottom]:border-l-0"
    assert classes.include?("data-[side=bottom]:border-b"), "Expected data-[side=bottom]:border-b"
    assert classes.include?("data-[side=bottom]:border-r"), "Expected data-[side=bottom]:border-r"
    assert classes.include?("data-[side=left]:border-t-0"), "Expected data-[side=left]:border-t-0"
    assert classes.include?("data-[side=left]:border-l-0"), "Expected data-[side=left]:border-l-0"
    assert classes.include?("data-[side=left]:border-b"), "Expected data-[side=left]:border-b"
    assert classes.include?("data-[side=right]:border-t-0"), "Expected data-[side=right]:border-t-0"
    assert classes.include?("data-[side=right]:border-l-0"), "Expected data-[side=right]:border-l-0"
    assert classes.include?("data-[side=right]:border-t"), "Expected data-[side=right]:border-t"
    assert classes.include?("data-[side=right]:border-r"), "Expected data-[side=right]:border-r"
  end

  def test_arrow_side_matches_content_side
    # Arrow's data-side matches the content's data-side
    render_inline(UI::Popover.new) do |popover|
      popover.with_trigger { "Trigger" }
      popover.with_content(side: :bottom) { "Content" }
    end
    content = page.find("[role='dialog']", visible: false)
    arrow = page.find("[data-ui--popover-target='arrow']", visible: false)
    assert_equal content[:"data-side"], arrow[:"data-side"]
    assert_equal "bottom", arrow[:"data-side"]
  end
end

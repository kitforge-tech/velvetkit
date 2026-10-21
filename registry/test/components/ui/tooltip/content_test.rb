# frozen_string_literal: true

require "test_helper"

class UI::Tooltip::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    result = render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Tooltip content" }
    end
    # Tooltip content is hidden by default, check it's in the HTML
    assert result.to_html.include?("Tooltip content")
  end

  def test_has_role_tooltip
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    assert_selector "[role='tooltip']", visible: false
  end

  def test_is_initially_hidden
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert content[:hidden].present?
  end

  def test_has_data_target
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "content", content[:"data-ui--tooltip-target"]
  end

  def test_default_side_top
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_side
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content(side: :right) { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "right", content[:"data-side"]
  end

  def test_custom_align
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content(align: :end) { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_equal "end", content[:"data-align"]
  end

  def test_has_animation_classes
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert content[:class].include?("animate-in")
    assert content[:class].include?("fade-in-0")
  end

  def test_custom_class_merge
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content(class: "custom-content") { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    assert_includes content[:class].split, "custom-content"
  end

  # Both tokens invert together, so the tooltip stays readable in either theme.
  # A pinned near-white (text-slate-50) sat on a near-white bg-foreground in
  # dark mode and was unreadable.
  def test_uses_inverted_surface_tokens
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    content = page.find("[role='tooltip']", visible: false)
    classes = content[:class].split
    assert_includes classes, "bg-foreground"
    assert_includes classes, "text-background"
    refute_includes classes, "text-slate-50"
  end

  def test_does_not_clip_overflow
    # Floating UI positions the arrow partially outside the content box
    # via negative staticSide offset; overflow-hidden would clip it.
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    classes = page.find("[role='tooltip']", visible: false)[:class].split
    refute_includes classes, "overflow-hidden"
  end

  def test_has_arrow_element
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    assert_selector "[data-ui--tooltip-target='arrow']", visible: false
  end

  def test_arrow_has_matching_background_and_rotation
    render_inline(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger { "Trigger" }
      tooltip.with_content { "Content" }
    end
    arrow = page.find("[data-ui--tooltip-target='arrow']", visible: false)
    classes = arrow[:class].split
    assert_includes classes, "bg-foreground"
    assert_includes classes, "rotate-45"
    assert_includes classes, "absolute"
  end
end

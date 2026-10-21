# frozen_string_literal: true

require "test_helper"

class UI::Accordion::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_button_inside_heading
    render_inline(UI::Accordion::Trigger.new) { "Trigger" }
    assert_selector "h3 button", text: "Trigger"
  end

  def test_has_aria_expanded_false_by_default
    render_inline(UI::Accordion::Trigger.new) { "x" }
    btn = page.find("button")
    assert_equal "false", btn["aria-expanded"]
  end

  def test_has_stimulus_target_and_action
    render_inline(UI::Accordion::Trigger.new) { "x" }
    btn = page.find("button")
    assert_equal "trigger", btn["data-ui--accordion-target"]
    assert_includes btn["data-action"], "click->ui--accordion#toggle"
    assert_includes btn["data-action"], "keydown->ui--accordion#keydown"
  end

  def test_renders_chevron_icon
    render_inline(UI::Accordion::Trigger.new) { "x" }
    assert_selector "button i[data-lucide='chevron-right']"
  end

  def test_aria_controls_when_content_id_provided
    render_inline(UI::Accordion::Trigger.new(content_id: "panel-1")) { "x" }
    btn = page.find("button")
    assert_equal "panel-1", btn["aria-controls"]
  end

  def test_auto_generated_id
    render_inline(UI::Accordion::Trigger.new) { "x" }
    btn = page.find("button")
    assert btn[:id].present?
    assert btn[:id].start_with?("ui-accordion-trigger-")
  end

  def test_custom_id_preserved
    render_inline(UI::Accordion::Trigger.new(id: "my-trigger")) { "x" }
    assert_selector "button#my-trigger"
  end

  def test_disabled
    render_inline(UI::Accordion::Trigger.new(disabled: true)) { "x" }
    assert_selector "button[disabled]"
  end

  def test_default_classes
    render_inline(UI::Accordion::Trigger.new) { "x" }
    classes = page.find("button")[:class].split
    assert_includes classes, "group"
    assert_includes classes, "flex"
    assert_includes classes, "w-full"
    assert_includes classes, "items-center"
    assert_includes classes, "gap-3"
    assert_includes classes, "py-2"
    assert_includes classes, "text-sm"
    assert_includes classes, "font-medium"
    assert_includes classes, "text-primary"
  end

  def test_user_class_merge
    render_inline(UI::Accordion::Trigger.new(class: "bg-red-500")) { "x" }
    classes = page.find("button")[:class].split
    assert_includes classes, "bg-red-500"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Accordion::Trigger.new(data: { test_id: "trig" })) { "x" }
    assert_selector "button[data-test-id='trig']"
  end
end

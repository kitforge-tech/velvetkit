# frozen_string_literal: true

require "test_helper"

class UI::Accordion::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def content_el
    page.find("[data-ui--accordion-target='content']")
  end

  def test_renders_collapsed_by_default
    render_inline(UI::Accordion::Content.new) { "Body" }
    assert_equal "closed", content_el["data-state"]
    assert_includes content_el[:class], "grid-rows-[0fr]"
  end

  def test_has_region_role
    render_inline(UI::Accordion::Content.new) { "Body" }
    assert_equal "region", content_el[:role]
  end

  def test_aria_labelledby_when_trigger_id_provided
    render_inline(UI::Accordion::Content.new(trigger_id: "trigger-1")) { "Body" }
    assert_equal "trigger-1", content_el["aria-labelledby"]
  end

  def test_auto_generated_id
    render_inline(UI::Accordion::Content.new) { "Body" }
    assert content_el[:id].present?
    assert content_el[:id].start_with?("ui-accordion-content-")
  end

  def test_custom_id_preserved
    render_inline(UI::Accordion::Content.new(id: "my-content")) { "Body" }
    assert_selector "[data-ui--accordion-target='content']#my-content"
  end

  def test_renders_content
    render_inline(UI::Accordion::Content.new) { "Body text" }
    assert_selector "[data-ui--accordion-target='content']", text: "Body text"
  end

  def test_wrapper_uses_grid_animation_classes
    render_inline(UI::Accordion::Content.new) { "x" }
    classes = content_el[:class].split
    assert_includes classes, "grid"
    assert_includes classes, "grid-rows-[0fr]"
    assert_includes classes, "transition-[grid-template-rows]"
    assert_includes classes, "duration-200"
  end

  def test_user_class_merge
    render_inline(UI::Accordion::Content.new(class: "bg-red-500")) { "x" }
    classes = content_el[:class].split
    assert_includes classes, "bg-red-500"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Accordion::Content.new(data: { test_id: "content-x" })) { "x" }
    assert_selector "[data-test-id='content-x']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::Accordion::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div_with_item_target
    render_inline(UI::Accordion::Item.new(value: "test")) { "Content" }
    div = page.find("[data-ui--accordion-target='item']")
    assert_equal "test", div["data-value"]
    assert_equal "closed", div["data-state"]
  end

  def test_renders_trigger_slot
    render_inline(UI::Accordion::Item.new(value: "test")) do |item|
      item.with_trigger { "Trigger" }
    end
    assert_selector "button[data-ui--accordion-target='trigger']", text: "Trigger"
  end

  def test_renders_content_slot_via_with_content_alias
    render_inline(UI::Accordion::Item.new(value: "test")) do |item|
      item.with_content { "Body" }
    end
    assert_selector "[data-ui--accordion-target='content']", text: "Body", visible: :all
  end

  def test_renders_trigger_and_content_together
    render_inline(UI::Accordion::Item.new(value: "test")) do |item|
      item.with_trigger { "Trigger" }
      item.with_content { "Body" }
    end
    assert_selector "button", text: "Trigger"
    assert_selector "[data-ui--accordion-target='content']", text: "Body", visible: :all
  end

  def test_default_classes
    render_inline(UI::Accordion::Item.new(value: "test")) { "x" }
    classes = page.find("[data-ui--accordion-target='item']")[:class].split
    assert_includes classes, "border-b"
  end

  def test_last_item_no_border
    render_inline(UI::Accordion::Item.new(value: "test", class: "last:border-b-0")) { "x" }
    classes = page.find("[data-ui--accordion-target='item']")[:class].split
    assert_includes classes, "last:border-b-0"
  end

  def test_user_class_merge
    render_inline(UI::Accordion::Item.new(value: "test", class: "my-item")) { "x" }
    classes = page.find("[data-ui--accordion-target='item']")[:class].split
    assert_includes classes, "my-item"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Accordion::Item.new(value: "test", data: { test_id: "item-x" })) { "x" }
    assert_selector "[data-ui--accordion-target='item'][data-test-id='item-x']"
  end
end

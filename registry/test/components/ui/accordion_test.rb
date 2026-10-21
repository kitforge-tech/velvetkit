# frozen_string_literal: true

require "test_helper"

class UI::AccordionTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_accordion(type: :single, default_value: "item-1")
    render_inline(UI::Accordion.new(type: type, default_value: default_value)) do |accordion|
      accordion.with_item(value: "item-1") do |item|
        item.with_trigger { "Trigger 1" }
        item.with_content { "Content 1" }
      end
      accordion.with_item(value: "item-2") do |item|
        item.with_trigger { "Trigger 2" }
        item.with_content { "Content 2" }
      end
    end
  end

  def test_root_carries_controller
    render_accordion
    root = page.find("[data-controller~='ui--accordion']")
    assert root.present?
  end

  def test_single_type_value
    render_accordion(type: :single)
    root = page.find("[data-controller~='ui--accordion']")
    assert_equal "single", root["data-ui--accordion-type-value"]
  end

  def test_multiple_type_value
    render_accordion(type: :multiple, default_value: [ "item-1", "item-2" ])
    root = page.find("[data-controller~='ui--accordion']")
    assert_equal "multiple", root["data-ui--accordion-type-value"]
  end

  def test_default_single_value
    render_accordion(default_value: "item-1")
    root = page.find("[data-controller~='ui--accordion']")
    assert_includes root["data-ui--accordion-values-value"], "item-1"
  end

  def test_no_default_value_yields_empty_array
    render_inline(UI::Accordion.new) do |accordion|
      accordion.with_item(value: "x") { |i| i.with_trigger { "T" }; i.with_content { "C" } }
    end
    root = page.find("[data-controller~='ui--accordion']")
    assert_equal "[]", root["data-ui--accordion-values-value"]
  end

  def test_renders_items
    render_accordion
    items = page.all("[data-ui--accordion-target='item']")
    assert_equal 2, items.size
  end

  def test_root_classes
    render_accordion
    root = page.find("[data-controller~='ui--accordion']")
    classes = root[:class].split
    assert_includes classes, "w-full"
  end

  def test_user_class_merge
    render_inline(UI::Accordion.new(class: "my-custom")) do |accordion|
      accordion.with_item(value: "x") { |i| i.with_trigger { "T" }; i.with_content { "C" } }
    end
    classes = page.find("[data-controller~='ui--accordion']")[:class].split
    assert_includes classes, "my-custom"
    assert_includes classes, "w-full"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Accordion.new(data: { test_id: "acc-x" })) do |accordion|
      accordion.with_item(value: "x") { |i| i.with_trigger { "T" }; i.with_content { "C" } }
    end
    assert_selector "[data-controller~='ui--accordion'][data-test-id='acc-x']"
  end

  def test_auto_generated_id
    render_accordion
    root = page.find("[data-controller~='ui--accordion']")
    assert root[:id].present?
    assert root[:id].start_with?("ui-accordion-")
  end

  def test_custom_id_preserved
    render_inline(UI::Accordion.new(id: "my-accordion")) do |accordion|
      accordion.with_item(value: "x") { |i| i.with_trigger { "T" }; i.with_content { "C" } }
    end
    assert_selector "[data-controller~='ui--accordion']#my-accordion"
  end
end

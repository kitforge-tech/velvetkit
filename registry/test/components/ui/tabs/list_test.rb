# frozen_string_literal: true

require "test_helper"

class UI::Tabs::ListTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_list(variant: :line)
    render_inline(UI::Tabs.new(default_value: "a", variant: variant)) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "a") { "A" }
        list.with_trigger(value: "b") { "B" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
      tabs.with_panel(value: "b") { "panel-b" }
    end
  end

  def test_renders_tablist_role
    render_list
    assert_selector "[role='tablist']"
  end

  def test_line_variant_classes
    render_list(variant: :line)
    classes = page.find("[role='tablist']")[:class].split
    assert_includes classes, "inline-flex"
    assert_includes classes, "border-b"
    assert_includes classes, "border-input"
  end

  def test_pill_variant_classes
    render_list(variant: :pill)
    classes = page.find("[role='tablist']")[:class].split
    assert_includes classes, "bg-muted"
    assert_includes classes, "p-1"
    assert_includes classes, "rounded-md"
  end

  def test_solid_variant_classes
    render_list(variant: :solid)
    classes = page.find("[role='tablist']")[:class].split
    assert_includes classes, "border"
    assert_includes classes, "divide-x"
    assert_includes classes, "bg-background"
  end

  def test_user_class_merge
    render_inline(UI::Tabs.new(default_value: "a")) do |tabs|
      tabs.with_list(class: "my-list-class") do |list|
        list.with_trigger(value: "a") { "A" }
      end
      tabs.with_panel(value: "a") { "panel-a" }
    end
    classes = page.find("[role='tablist']")[:class].split
    assert_includes classes, "my-list-class"
  end

  def test_triggers_rendered_inside_list
    render_list
    triggers = page.all("[role='tablist'] [role='tab']")
    assert_equal 2, triggers.size
  end
end

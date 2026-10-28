# frozen_string_literal: true

require "test_helper"

class UI::CollapsibleTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_collapsible(**opts)
    render_inline(UI::Collapsible.new(**opts)) do |c|
      c.with_trigger { "Forms" }
      "<a href='/input'>Input</a>".html_safe
    end
  end

  def test_renders_details_with_summary_trigger
    render_collapsible
    assert_selector "details > summary", text: "Forms"
    assert_selector "details > summary + div > a[href='/input']", visible: :all
  end

  def test_closed_by_default
    render_collapsible
    assert_selector "details:not([open])", visible: :all
  end

  def test_open
    render_collapsible(open: true)
    assert_selector "details[open]"
    assert_selector "a[href='/input']", text: "Input"
  end

  def test_chevron_is_decorative_and_turns_when_open
    render_collapsible
    icon = page.find("summary [aria-hidden='true']", visible: :all)
    assert_includes icon[:class].split, "group-open/collapsible:rotate-90"
  end

  def test_hides_the_native_marker
    render_collapsible
    classes = page.find("summary")[:class].split
    assert_includes classes, "list-none"
    assert_includes classes, "[&::-webkit-details-marker]:hidden"
  end

  def test_sizes
    render_collapsible(size: :sm)
    assert_includes page.find("summary")[:class].split, "text-xs"
  end

  def test_trigger_and_content_classes
    render_collapsible(trigger_class: "font-semibold", content_class: "ml-3 border-l")
    assert_includes page.find("summary")[:class].split, "font-semibold"
    assert_includes page.find("details > div", visible: :all)[:class].split, "border-l"
  end

  def test_html_attrs_and_class_on_details
    render_collapsible(id: "forms-tree", class: "mt-2", data: { test_id: "tree" })
    details = page.find("details#forms-tree[data-test-id='tree']", visible: :all)
    assert_includes details[:class].split, "mt-2"
    assert_includes details[:class].split, "group/collapsible"
  end

  def test_nests
    render_inline(UI::Collapsible.new(open: true)) do |outer|
      outer.with_trigger { "Components" }
      vc_test_controller.view_context.render(UI::Collapsible.new) { |inner| inner.with_trigger { "Forms" } }
    end
    assert_selector "details[open] > div > details > summary", text: "Forms"
  end
end

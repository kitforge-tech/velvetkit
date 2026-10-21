# frozen_string_literal: true

require "test_helper"

class UI::Breadcrumb::ListTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_ol
    render_inline(UI::Breadcrumb::List.new) { "Items" }
    assert_selector "ol", text: "Items"
  end

  def test_default_classes
    render_inline(UI::Breadcrumb::List.new) { "x" }
    classes = page.find("ol")[:class].split
    assert_includes classes, "flex"
    assert_includes classes, "flex-wrap"
    assert_includes classes, "items-center"
    assert_includes classes, "gap-1.5"
    assert_includes classes, "break-words"
  end

  def test_user_class_override
    render_inline(UI::Breadcrumb::List.new(class: "my-list")) { "x" }
    classes = page.find("ol")[:class].split
    assert_includes classes, "my-list"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Breadcrumb::List.new(id: "my-list", data: { test_id: "list" })) { "x" }
    assert_selector "ol#my-list[data-test-id='list']"
  end
end

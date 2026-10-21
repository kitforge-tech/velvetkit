# frozen_string_literal: true

require "test_helper"

class UI::Breadcrumb::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_li
    render_inline(UI::Breadcrumb::Item.new) { "Item" }
    assert_selector "li", text: "Item"
  end

  def test_default_classes
    render_inline(UI::Breadcrumb::Item.new) { "x" }
    classes = page.find("li")[:class].split
    assert_includes classes, "inline-flex"
    assert_includes classes, "items-center"
    assert_includes classes, "gap-1.5"
  end

  def test_user_class_override
    render_inline(UI::Breadcrumb::Item.new(class: "my-item")) { "x" }
    classes = page.find("li")[:class].split
    assert_includes classes, "my-item"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Breadcrumb::Item.new(id: "my-item", data: { test_id: "item" })) { "x" }
    assert_selector "li#my-item[data-test-id='item']"
  end

  def test_renders_with_link
    render_inline(UI::Breadcrumb::Item.new) do
      "<a href=\"/\">Home</a>".html_safe
    end
    assert_selector "li a[href='/']", text: "Home"
  end
end

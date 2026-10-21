# frozen_string_literal: true

require "test_helper"

class UI::Alert::DescriptionTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div
    render_inline(UI::Alert::Description.new) { "Description" }
    assert_selector "div", text: "Description"
  end

  def test_default_classes
    render_inline(UI::Alert::Description.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "text-sm"
    assert_includes classes, "leading-relaxed"
  end

  def test_user_class_override
    render_inline(UI::Alert::Description.new(class: "text-base")) { "Custom" }
    classes = page.find("div")[:class].split
    refute_includes classes, "text-sm"
    assert_includes classes, "text-base"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Alert::Description.new(id: "alert-desc", data: { test: "d" })) { "y" }
    assert_selector "div#alert-desc[data-test='d']"
  end

  def test_content_slot
    render_inline(UI::Alert::Description.new) { "Full description" }
    assert_equal "Full description", page.find("div").text.strip
  end
end

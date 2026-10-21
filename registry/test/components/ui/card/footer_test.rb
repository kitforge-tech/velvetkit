# frozen_string_literal: true

require "test_helper"

class UI::Card::FooterTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div
    render_inline(UI::Card::Footer.new) { "Footer" }
    assert_selector "div", text: "Footer"
  end

  def test_default_classes
    render_inline(UI::Card::Footer.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "flex"
    assert_includes classes, "items-center"
    assert_includes classes, "p-6"
    assert_includes classes, "pt-0"
  end

  def test_user_class_override
    render_inline(UI::Card::Footer.new(class: "p-4")) { "x" }
    classes = page.find("div")[:class].split
    refute_includes classes, "p-6"
    assert_includes classes, "p-4"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card::Footer.new(id: "my-footer", data: { test_id: "f" })) { "x" }
    assert_selector "div#my-footer[data-test-id='f']"
  end
end

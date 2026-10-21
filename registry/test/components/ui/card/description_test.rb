# frozen_string_literal: true

require "test_helper"

class UI::Card::DescriptionTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_p
    render_inline(UI::Card::Description.new) { "Description" }
    assert_selector "p", text: "Description"
  end

  def test_default_classes
    render_inline(UI::Card::Description.new) { "x" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-sm"
    assert_includes classes, "text-muted-foreground"
  end

  def test_user_class_override
    render_inline(UI::Card::Description.new(class: "text-xs")) { "x" }
    classes = page.find("p")[:class].split
    refute_includes classes, "text-sm"
    assert_includes classes, "text-xs"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card::Description.new(id: "my-desc", data: { test_id: "d" })) { "x" }
    assert_selector "p#my-desc[data-test-id='d']"
  end
end

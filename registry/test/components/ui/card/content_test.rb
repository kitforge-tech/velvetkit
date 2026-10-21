# frozen_string_literal: true

require "test_helper"

class UI::Card::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div
    render_inline(UI::Card::Content.new) { "Content" }
    assert_selector "div", text: "Content"
  end

  def test_default_classes
    render_inline(UI::Card::Content.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "p-6"
    assert_includes classes, "pt-0"
  end

  def test_user_class_override
    render_inline(UI::Card::Content.new(class: "p-4")) { "x" }
    classes = page.find("div")[:class].split
    refute_includes classes, "p-6"
    assert_includes classes, "p-4"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card::Content.new(id: "my-content", data: { test_id: "c" })) { "x" }
    assert_selector "div#my-content[data-test-id='c']"
  end

  # Content sits flush under a header, but needs its own top padding when it
  # is the first thing in the card.
  def test_content_first_in_a_card_gets_top_padding
    render_inline(UI::Card::Content.new) { "Body" }
    classes = page.find("div")[:class].split
    assert_includes classes, "pt-0"
    assert_includes classes, "first:pt-6"
  end
end

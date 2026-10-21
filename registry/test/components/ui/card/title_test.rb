# frozen_string_literal: true

require "test_helper"

class UI::Card::TitleTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h3
    render_inline(UI::Card::Title.new) { "Title" }
    assert_selector "h3", text: "Title"
  end

  def test_default_classes
    render_inline(UI::Card::Title.new) { "x" }
    classes = page.find("h3")[:class].split
    assert_includes classes, "text-lg"
    assert_includes classes, "font-semibold"
    assert_includes classes, "leading-none"
    assert_includes classes, "tracking-tight"
  end

  def test_user_class_override
    render_inline(UI::Card::Title.new(class: "text-xl")) { "x" }
    classes = page.find("h3")[:class].split
    refute_includes classes, "text-lg"
    assert_includes classes, "text-xl"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card::Title.new(id: "my-title", data: { test_id: "t" })) { "x" }
    assert_selector "h3#my-title[data-test-id='t']"
  end
end

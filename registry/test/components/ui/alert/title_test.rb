# frozen_string_literal: true

require "test_helper"

class UI::Alert::TitleTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h5
    render_inline(UI::Alert::Title.new) { "Title" }
    assert_selector "h5", text: "Title"
  end

  def test_default_classes
    render_inline(UI::Alert::Title.new) { "x" }
    classes = page.find("h5")[:class].split
    assert_includes classes, "font-medium"
    assert_includes classes, "leading-none"
    assert_includes classes, "tracking-tight"
  end

  def test_user_class_override
    render_inline(UI::Alert::Title.new(class: "font-normal")) { "Custom" }
    classes = page.find("h5")[:class].split
    refute_includes classes, "font-medium"
    assert_includes classes, "font-normal"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Alert::Title.new(id: "alert-title", data: { test: "t" })) { "y" }
    assert_selector "h5#alert-title[data-test='t']"
  end

  def test_content_slot
    render_inline(UI::Alert::Title.new) { "My Title" }
    assert_equal "My Title", page.find("h5").text.strip
  end
end

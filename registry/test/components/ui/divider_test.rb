# frozen_string_literal: true

require "test_helper"

class UI::DividerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_horizontal_hr_by_default
    render_inline(UI::Divider.new)
    hr = page.find("hr")
    classes = hr[:class].split
    assert_includes classes, "border-t"
    assert_includes classes, "w-full"
  end

  def test_renders_vertical_orientation
    render_inline(UI::Divider.new(orientation: :vertical))
    hr = page.find("hr")
    classes = hr[:class].split
    assert_includes classes, "border-l"
    assert_includes classes, "self-stretch"
    assert_includes classes, "h-full"
  end

  def test_with_label_renders_wrapper_div
    render_inline(UI::Divider.new(label: "OR"))
    assert_selector "div.flex"
    assert_selector "span", text: "OR"
  end

  def test_label_has_muted_foreground_color
    render_inline(UI::Divider.new(label: "Section"))
    span = page.find("span")
    classes = span[:class].split
    assert_includes classes, "text-muted-foreground"
    assert_includes classes, "text-xs"
  end

  def test_user_class_merge
    render_inline(UI::Divider.new(class: "my-4"))
    hr = page.find("hr")
    classes = hr[:class].split
    assert_includes classes, "my-4"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Divider.new(data: { test_id: "divider-x" }))
    assert_selector "hr[data-test-id='divider-x']"
  end

  def test_label_wrapper_includes_user_class
    render_inline(UI::Divider.new(label: "OR", class: "gap-4"))
    div = page.find("div")
    classes = div[:class].split
    assert_includes classes, "gap-4"
    assert_includes classes, "flex"
  end
end

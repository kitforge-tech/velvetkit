# frozen_string_literal: true

require "test_helper"

class UI::Breadcrumb::SeparatorTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_li_with_presentation_role
    render_inline(UI::Breadcrumb::Separator.new)
    assert_selector "li[role='presentation']"
  end

  def test_renders_slash
    render_inline(UI::Breadcrumb::Separator.new)
    assert_selector "li span", text: "/"
  end

  def test_span_is_aria_hidden
    render_inline(UI::Breadcrumb::Separator.new)
    span = page.find("li > span")
    assert_equal "true", span["aria-hidden"]
  end

  def test_default_classes
    render_inline(UI::Breadcrumb::Separator.new)
    classes = page.find("li > span")[:class].split
    assert_includes classes, "text-muted-foreground/70"
  end

  def test_user_class_override
    render_inline(UI::Breadcrumb::Separator.new(class: "my-sep"))
    classes = page.find("li > span")[:class].split
    assert_includes classes, "my-sep"
  end
end

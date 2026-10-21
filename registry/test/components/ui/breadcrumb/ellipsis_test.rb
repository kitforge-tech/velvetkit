# frozen_string_literal: true

require "test_helper"

class UI::Breadcrumb::EllipsisTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_li
    render_inline(UI::Breadcrumb::Ellipsis.new)
    assert_selector "li"
  end

  def test_renders_ellipsis_icon
    render_inline(UI::Breadcrumb::Ellipsis.new)
    assert_selector "li i[data-lucide='ellipsis']"
  end

  def test_static_ellipsis_is_fully_decorative
    render_inline(UI::Breadcrumb::Ellipsis.new)
    assert_selector "li > span[role='presentation']"
    assert_selector "li > span[aria-hidden='true']"
    refute_selector "li .sr-only"
  end

  def test_user_class_override
    render_inline(UI::Breadcrumb::Ellipsis.new(class: "my-ellipsis"))
    classes = page.find("li > span")[:class].split
    assert_includes classes, "my-ellipsis"
  end

  def test_renders_popover_when_content_present
    render_inline(UI::Breadcrumb::Ellipsis.new) do
      "<a href=\"/docs\">Documentation</a>".html_safe
    end
    assert_selector "li button[aria-label='More breadcrumb pages']"
    assert_selector "li i[data-lucide='ellipsis']"
  end

  def test_popover_content_includes_provided_html
    render_inline(UI::Breadcrumb::Ellipsis.new) do
      "<li>Docs</li><li>Components</li>".html_safe
    end
    assert_selector "li button[aria-label='More breadcrumb pages']"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Breadcrumb::Ellipsis.new(id: "my-ellipsis", data: { test_id: "ell" }))
    assert_selector "li#my-ellipsis[data-test-id='ell']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::Card::HeaderTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div
    render_inline(UI::Card::Header.new) { "Header" }
    assert_selector "div", text: "Header"
  end

  def test_default_classes
    render_inline(UI::Card::Header.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "flex"
    assert_includes classes, "flex-col"
    assert_includes classes, "gap-1.5"
    assert_includes classes, "p-6"
  end

  def test_renders_with_title_slot
    render_inline(UI::Card::Header.new) do |header|
      header.with_title { "Title" }
    end
    assert_selector "h3", text: "Title"
  end

  def test_renders_with_description_slot
    render_inline(UI::Card::Header.new) do |header|
      header.with_description { "Description" }
    end
    assert_selector "p", text: "Description"
  end

  def test_renders_title_and_description_together
    render_inline(UI::Card::Header.new) do |header|
      header.with_title { "Title" }
      header.with_description { "Description" }
    end
    header_el = page.find("div")
    assert_equal "TitleDescription", header_el.text.gsub(/\s+/, "")
  end

  def test_user_class_override
    render_inline(UI::Card::Header.new(class: "p-4")) { "x" }
    classes = page.find("div")[:class].split
    refute_includes classes, "p-6"
    assert_includes classes, "p-4"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card::Header.new(id: "my-header", data: { test_id: "hdr" })) { "x" }
    assert_selector "div#my-header[data-test-id='hdr']"
  end
end

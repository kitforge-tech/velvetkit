# frozen_string_literal: true

require "test_helper"

class UI::CardTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_default_card
    render_inline(UI::Card.new) { "Card content" }
    assert_selector "div", text: "Card content"
  end

  def test_root_classes
    render_inline(UI::Card.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "rounded-xl"
    assert_includes classes, "border"
    assert_includes classes, "bg-card"
    assert_includes classes, "text-card-foreground"
    assert_includes classes, "shadow"
  end

  def test_renders_with_header_slot
    render_inline(UI::Card.new) do |card|
      card.with_header { "Header" }
      "Body"
    end
    assert_selector "div div", text: "Header"
  end

  def test_renders_with_content_slot
    render_inline(UI::Card.new) do |card|
      card.with_content { "Content" }
    end
    assert_selector "div div", text: "Content"
  end

  def test_renders_with_footer_slot
    render_inline(UI::Card.new) do |card|
      card.with_footer { "Footer" }
    end
    assert_selector "div div", text: "Footer"
  end

  def test_renders_all_slots_together
    render_inline(UI::Card.new(id: "all-slots")) do |card|
      card.with_header { "Header" }
      card.with_content { "Content" }
      card.with_footer { "Footer" }
    end
    card_el = page.find("div#all-slots")
    assert_equal "HeaderContentFooter", card_el.text.gsub(/\s+/, "")
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::Card.new(class: "bg-red-500")) { "x" }
    classes = page.find("div")[:class].split
    refute_includes classes, "bg-card"
    assert_includes classes, "bg-red-500"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Card.new(id: "my-card", data: { test_id: "card-x" })) { "x" }
    assert_selector "div#my-card[data-test-id='card-x']"
  end
end

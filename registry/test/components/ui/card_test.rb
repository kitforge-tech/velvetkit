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
    assert_includes classes, "ring-1"
    assert_includes classes, "bg-card"
    assert_includes classes, "text-card-foreground"
    assert_not_includes classes, "overflow-hidden"
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

  def root = page.find("[data-slot='card']")

  def test_size_and_spacing
    render_inline(UI::Card.new) { "x" }
    assert_equal "default", root["data-size"]
    assert_includes root[:style], "--card-spacing: calc(var(--spacing) * 4)"
    render_inline(UI::Card.new(size: :sm)) { "x" }
    assert_equal "sm", root["data-size"]
    assert_includes root[:style], "calc(var(--spacing) * 3)"
    render_inline(UI::Card.new(size: :sm, spacing: 8)) { "x" }
    assert_includes root[:style], "calc(var(--spacing) * 8)"
    render_inline(UI::Card.new(size: :nonsense)) { "x" }
    assert_equal "default", root["data-size"]
  end

  def test_keeps_the_apps_style_and_data
    render_inline(UI::Card.new(style: "max-width: 10rem", data: { testid: "c" })) { "x" }
    assert_includes root[:style], "max-width: 10rem"
    assert_equal "c", root["data-testid"]
    assert_equal "card", root["data-slot"]
  end

  def test_each_part_is_marked_so_the_card_can_lay_itself_out
    render_inline(UI::Card.new) do |card|
      card.with_header do |header|
        header.with_title { "T" }
        header.with_description { "D" }
        header.with_action { "A" }
      end
      card.with_content { "C" }
      card.with_footer { "F" }
    end
    assert_selector "[data-slot='card'] > [data-slot='card-header'] > h3[data-slot='card-title']", text: "T"
    assert_selector "[data-slot='card-header'] > p[data-slot='card-description']", text: "D"
    assert_selector "[data-slot='card-header'] > [data-slot='card-action']", text: "A"
    assert_selector "[data-slot='card'] > [data-slot='card-content']", text: "C"
    assert_selector "[data-slot='card'] > [data-slot='card-footer']", text: "F"
  end

  def test_image_comes_first_edge_to_edge
    render_inline(UI::Card.new) do |card|
      card.with_header { "H" }
      card.with_image(src: "data:image/gif;base64,R0lGOD", alt: "A hill", class: "aspect-square")
    end
    image = page.find("[data-slot='card'] > img:first-child")
    assert_equal "card-image", image["data-slot"]
    assert_equal "A hill", image[:alt]
    classes = image[:class].split
    assert_includes classes, "rounded-t-xl"
    assert_includes classes, "aspect-square"
    assert_not_includes classes, "aspect-video"
  end

  def test_a_block_with_no_parts_has_no_part_styles_of_its_own
    render_inline(UI::Card.new(class: "p-6")) { "<div>raw</div>".html_safe }
    assert_no_selector "[data-slot='card'] > [data-slot^='card-']"
    assert_includes root[:class].split, "p-6"
    assert_not_includes root[:class].split, "flex"
    assert_not_includes root[:class].split, "text-sm"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::Menu::LabelTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    render_inline(UI::Menu::Label.new) { "My Label" }
    assert_text "My Label"
  end

  def test_renders_label_param
    render_inline(UI::Menu::Label.new("Label text"))
    assert_text "Label text"
  end

  def test_renders_block_over_label
    render_inline(UI::Menu::Label.new("Label text")) { "Block text" }
    assert_text "Block text"
    refute_text "Label text"
  end

  def test_has_styling
    render_inline(UI::Menu::Label.new) { "Label" }
    label = page.find("div", text: "Label")
    assert label[:class].include?("font-semibold")
    assert label[:class].include?("text-muted-foreground")
  end

  def test_inset_padding
    render_inline(UI::Menu::Label.new(inset: true)) { "Label" }
    label = page.find("div", text: "Label")
    assert_includes label[:class].split, "pl-8"
  end

  def test_custom_class_merge
    render_inline(UI::Menu::Label.new(class: "custom-label")) { "Label" }
    label = page.find("div", text: "Label")
    assert_includes label[:class].split, "custom-label"
  end
end

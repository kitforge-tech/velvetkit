# frozen_string_literal: true

require "test_helper"

class UI::Menu::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_as_button_by_default
    render_inline(UI::Menu::Item.new) { "Item text" }
    assert_selector "button", text: "Item text"
  end

  def test_renders_as_link_with_href
    render_inline(UI::Menu::Item.new(href: "/profile")) { "Profile" }
    assert_selector "a[href='/profile']", text: "Profile"
  end

  def test_renders_label_param
    render_inline(UI::Menu::Item.new("Label text"))
    assert_selector "button", text: "Label text"
  end

  def test_renders_block_over_label
    render_inline(UI::Menu::Item.new("Label text")) { "Block text" }
    assert_selector "button", text: "Block text"
    refute_text "Label text"
  end

  def test_has_role_menuitem
    render_inline(UI::Menu::Item.new) { "Item" }
    assert_selector "[role='menuitem']"
  end

  def test_has_tabindex_minus_one
    render_inline(UI::Menu::Item.new) { "Item" }
    item = page.find("[role='menuitem']")
    assert_equal "-1", item[:tabindex]
  end

  def test_has_data_target
    render_inline(UI::Menu::Item.new) { "Item" }
    assert_selector "[data-ui--menu-target='item']"
  end

  def test_disabled_state
    render_inline(UI::Menu::Item.new(disabled: true)) { "Disabled" }
    item = page.find("[role='menuitem']")
    assert item[:disabled].present?
    assert_equal "true", item[:"data-disabled"]
  end

  def test_default_variant
    render_inline(UI::Menu::Item.new) { "Item" }
    item = page.find("[role='menuitem']")
    refute_includes item[:class].split, "text-destructive"
  end

  def test_destructive_variant
    render_inline(UI::Menu::Item.new(variant: :destructive)) { "Delete" }
    item = page.find("[role='menuitem']")
    assert_includes item[:class].split, "text-destructive"
  end

  def test_inset_padding
    render_inline(UI::Menu::Item.new(inset: true)) { "Item" }
    item = page.find("[role='menuitem']")
    assert_includes item[:class].split, "pl-8"
  end

  def test_custom_class_merge
    render_inline(UI::Menu::Item.new(class: "custom-item")) { "Item" }
    item = page.find("[role='menuitem']")
    assert_includes item[:class].split, "custom-item"
  end
end

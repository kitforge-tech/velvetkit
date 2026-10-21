# frozen_string_literal: true

require "test_helper"

class UI::Dialog::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_dialog(trigger_args = {}, &block)
    render_inline(UI::Dialog.new(id: "profile-dialog")) do |dlg|
      dlg.with_trigger(**trigger_args) { "Open" }
      dlg.with_content { |c| c.with_title("Hi"); block&.call(c) }
    end
  end

  def test_default_renders_ui_button
    render_dialog
    btn = page.find("[data-ui--dialog-target='trigger']")
    assert_equal "button", btn.tag_name
    assert_equal "button", btn[:type]
    assert_equal "Open",   btn.text.strip
    classes = btn[:class].split
    assert_includes classes, "bg-primary"
    assert_includes classes, "h-9"
  end

  def test_variant_option_passed_to_button
    render_dialog(variant: :outline)
    btn = page.find("[data-ui--dialog-target='trigger']")
    assert_includes btn[:class], "border-input"
  end

  def test_size_option_passed_to_button
    render_dialog(size: :sm)
    btn = page.find("[data-ui--dialog-target='trigger']")
    assert_includes btn[:class].split, "h-8"
  end

  def test_as_renders_alternate_tag
    render_dialog(as: :a, href: "#open")
    el = page.find("[data-ui--dialog-target='trigger']")
    assert_equal "a", el.tag_name
    assert_equal "#open", el[:href]
  end

  def test_data_action_wires_open
    render_dialog
    action = page.find("[data-ui--dialog-target='trigger']")["data-action"]
    assert_match(/click->ui--dialog#open/, action)
  end

  def test_aria_attributes_link_to_dialog
    render_dialog
    btn    = page.find("[data-ui--dialog-target='trigger']")
    dialog = page.find("dialog", visible: :all)
    assert_equal "dialog",        btn["aria-haspopup"]
    assert_equal "false",         btn["aria-expanded"]
    assert_equal dialog[:id],     btn["aria-controls"]
    assert_equal "profile-dialog", dialog[:id]
  end

  def test_user_class_merge
    render_dialog(class: "px-8")
    classes = page.find("[data-ui--dialog-target='trigger']")[:class].split
    assert_includes classes, "px-8"
  end

  def test_caller_data_action_is_preserved_alongside_open_action
    render_dialog(data: { action: "mouseenter->something#hover" })
    action = page.find("[data-ui--dialog-target='trigger']")["data-action"]
    assert_match(/mouseenter->something#hover/, action)
    assert_match(/click->ui--dialog#open/,      action)
  end
end

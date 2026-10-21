# frozen_string_literal: true

require "test_helper"

class UI::SheetTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_sheet(**opts)
    render_inline(UI::Sheet.new(**opts)) do |sheet|
      sheet.with_trigger { "Open sheet" }
      sheet.with_content do |content|
        content.with_title { "Edit profile" }
        content.with_description { "Make changes to your profile here." }
        "Sheet body"
      end
    end
  end

  def test_root_carries_dialog_controller
    render_sheet
    assert_selector "[data-controller~='ui--dialog']"
  end

  def test_dialog_element_has_generated_id
    render_sheet
    dialog = page.find("dialog", visible: :all)
    assert dialog[:id].present?
    assert dialog[:id].start_with?("ui-sheet-")
  end

  def test_custom_id_lands_on_dialog_element
    render_sheet(id: "profile-sheet")
    assert_selector "dialog#profile-sheet", visible: :all
  end

  def test_user_class_merge
    render_sheet(class: "my-sheet-root")
    classes = page.find("[data-controller~='ui--dialog']")[:class].split
    assert_includes classes, "my-sheet-root"
    assert_includes classes, "contents"
  end
end

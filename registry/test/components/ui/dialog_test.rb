# frozen_string_literal: true

require "test_helper"

class UI::DialogTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_dialog(**opts)
    render_inline(UI::Dialog.new(**opts)) do |dialog|
      dialog.with_trigger { "Open dialog" }
      dialog.with_content do |content|
        content.with_title { "Edit profile" }
        content.with_description { "Make changes to your profile here." }
        "Dialog body"
      end
    end
  end

  def test_root_carries_controller
    render_dialog
    assert_selector "[data-controller~='ui--dialog']"
  end

  def test_dialog_element_has_generated_id
    render_dialog
    dialog = page.find("dialog", visible: :all)
    assert dialog[:id].present?
    assert dialog[:id].start_with?("ui-dialog-")
  end

  def test_trigger_and_content_render
    result = render_dialog
    assert_text "Open dialog"
    assert result.to_html.include?("Dialog body")
  end

  def test_custom_id_lands_on_dialog_element
    render_dialog(id: "profile-dialog")
    assert_selector "dialog#profile-dialog", visible: :all
  end

  def test_user_class_merge
    render_dialog(class: "my-dialog-root")
    classes = page.find("[data-controller~='ui--dialog']")[:class].split
    assert_includes classes, "my-dialog-root"
    assert_includes classes, "contents"
  end

  def test_html_attrs_passthrough
    render_dialog(data: { test_id: "dialog-x" })
    assert_selector "[data-controller~='ui--dialog'][data-test-id='dialog-x']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::ConfirmDialogTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def dialog = page.find("dialog", visible: :all)

  def test_a_native_dialog_wired_to_the_controller
    render_inline(UI::ConfirmDialog.new)
    assert_equal "ui--confirm-dialog", dialog["data-controller"]
    assert_equal "confirm-dialog", dialog["data-slot"]
    assert_equal "ui-confirm-dialog", dialog[:id]
  end

  def test_labelled_by_its_title_and_described_by_its_description
    render_inline(UI::ConfirmDialog.new)
    id = dialog[:id]
    assert_equal "#{id}-title", dialog["aria-labelledby"]
    assert_equal "#{id}-description", dialog["aria-describedby"]
    assert_selector "h2##{id}-title[data-ui--confirm-dialog-target='title']", visible: :all
    assert_selector "p##{id}-description[hidden]", visible: :all
  end

  def test_buttons_submit_a_dialog_form_with_their_answer
    render_inline(UI::ConfirmDialog.new)
    assert_selector "dialog form[method='dialog']", visible: :all
    assert_selector "button[type='submit'][value='cancel'][autofocus]", text: "Cancel", visible: :all
    assert_selector "button[type='submit'][value='confirm'][data-ui--confirm-dialog-target='confirm']",
                    text: "Confirm", visible: :all
  end

  def test_a_hidden_destructive_confirm_for_the_controller_to_swap_in
    render_inline(UI::ConfirmDialog.new)
    button = page.find("[data-ui--confirm-dialog-target='destructive']", visible: :all)
    assert button[:hidden]
    assert_includes button[:class].split, "bg-destructive"
  end

  def test_labels_are_passed_to_the_controller
    render_inline(UI::ConfirmDialog.new(confirm_label: "Yes", cancel_label: "No"))
    assert_equal "Yes", dialog["data-ui--confirm-dialog-confirm-label-value"]
    assert_equal "No", dialog["data-ui--confirm-dialog-cancel-label-value"]
    assert_selector "button[value='cancel']", text: "No", visible: :all
  end

  def test_labels_come_from_i18n
    # Built from the dotted scope so the namespaced run stores it under its own scope.
    labels = "ui.confirm_dialog".split(".").reverse.inject({ confirm: "OK", cancel: "Never mind" }) { |h, k| { k => h } }
    I18n.backend.store_translations(:en, labels)
    render_inline(UI::ConfirmDialog.new)
    assert_equal "OK", dialog["data-ui--confirm-dialog-confirm-label-value"]
    assert_equal "Never mind", dialog["data-ui--confirm-dialog-cancel-label-value"]
  ensure
    I18n.reload!
  end

  def test_id_class_and_attrs
    render_inline(UI::ConfirmDialog.new(id: "confirm", class: "p-8", data: { test_id: "c" }))
    assert_equal "confirm", dialog[:id]
    assert_equal "confirm-title", dialog["aria-labelledby"]
    assert_equal "c", dialog["data-test-id"]
    assert_includes dialog[:class].split, "p-8"
    refute_includes dialog[:class].split, "p-4"
  end
end

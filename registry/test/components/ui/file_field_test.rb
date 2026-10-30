# frozen_string_literal: true

require "test_helper"

class UI::FileFieldTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_a_file_input
    render_inline(UI::FileField.new)
    assert_selector "input[type='file']"
  end

  def test_input_is_screen_reader_only_not_hidden
    render_inline(UI::FileField.new)
    input = page.find("input", visible: :all)
    assert_includes input[:class].split, "sr-only"
    refute input[:hidden]
  end

  def test_dropzone_is_a_label_pointing_at_the_input
    render_inline(UI::FileField.new)
    label = page.find("label")
    input = page.find("input", visible: :all)
    assert_equal input[:id], label[:for]
  end

  def test_dropzone_wired_to_controller
    render_inline(UI::FileField.new)
    label = page.find("label")
    assert_equal "ui--file-field", label["data-controller"]
    assert_includes label["data-action"], "dragover->ui--file-field#dragOver"
    assert_includes label["data-action"], "dragleave->ui--file-field#dragLeave"
    assert_includes label["data-action"], "drop->ui--file-field#drop"
  end

  def test_input_wired_to_update_names_on_change
    render_inline(UI::FileField.new)
    input = page.find("input", visible: :all)
    assert_includes input["data-action"], "change->ui--file-field#updateNames"
  end

  def test_not_multiple_by_default
    render_inline(UI::FileField.new)
    refute page.find("input", visible: :all)[:multiple]
  end

  def test_multiple
    render_inline(UI::FileField.new(multiple: true))
    assert page.find("input", visible: :all)[:multiple]
  end

  def test_accept
    render_inline(UI::FileField.new(accept: "image/*"))
    assert_equal "image/*", page.find("input", visible: :all)[:accept]
  end

  def test_disabled
    render_inline(UI::FileField.new(disabled: true))
    assert page.find("input", visible: :all)[:disabled]
    assert_includes page.find("label")[:class], "opacity-50"
  end

  def test_error_true_marks_the_input_invalid
    render_inline(UI::FileField.new(error: true))
    input = page.find("input", visible: :all)
    assert_equal "true", input["aria-invalid"]
    assert_includes page.find("label")[:class], "border-destructive"
  end

  # --- form-builder binding (Rails convention) ---

  class User
    include ActiveModel::Model
    attr_accessor :avatar
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:user, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_scopes_the_field_name
    render_inline(UI::FileField.new(form: form_builder_for(User.new), field: :avatar))
    assert_selector "input[type='file'][name='user[avatar]']"
  end

  def test_label_is_derived_from_the_attribute_name
    render_inline(UI::FileField.new(form: form_builder_for(User.new), field: :avatar))
    assert_selector "label", text: "Avatar"
  end

  def test_hint_renders
    render_inline(UI::FileField.new(hint: "PNG or JPG, up to 5MB"))
    assert_text "PNG or JPG, up to 5MB"
  end

  def test_html_attrs_passthrough
    render_inline(UI::FileField.new(id: "my-id", data: { test_id: "f" }))
    assert_selector "input#my-id[data-test-id='f']", visible: :all
  end
end

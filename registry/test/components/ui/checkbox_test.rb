# frozen_string_literal: true

require "test_helper"

class UI::CheckboxTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_input_type_checkbox_with_appearance_none
    render_inline(UI::Checkbox.new(name: "test"))
    input = page.find("input[type='checkbox']")
    classes = input[:class].split
    assert_includes classes, "appearance-none"
    assert_includes classes, "peer"
  end

  def test_checked_adds_checked_attribute
    render_inline(UI::Checkbox.new(name: "test", checked: true))
    input = page.find("input[type='checkbox']")
    assert input["checked"].present?, "expected checked attribute"
  end

  def test_value_defaults_to_one
    render_inline(UI::Checkbox.new(name: "test"))
    input = page.find("input[type='checkbox']")
    assert_equal "1", input[:value]
  end

  def test_value_can_be_customized
    render_inline(UI::Checkbox.new(name: "test", value: "yes"))
    input = page.find("input[type='checkbox']")
    assert_equal "yes", input[:value]
  end

  def test_disabled_sets_disabled_attribute
    render_inline(UI::Checkbox.new(name: "test", disabled: true))
    input = page.find("input[disabled]")
    assert input.disabled?
  end

  def test_disabled_wrapper_has_cursor_and_opacity_classes
    render_inline(UI::Checkbox.new(name: "test", disabled: true, label: "Disabled"))
    label_el = page.find("label")
    classes = label_el[:class].split
    assert_includes classes, "cursor-not-allowed"
    assert_includes classes, "opacity-60"
  end

  def test_error_sets_aria_invalid_and_border_destructive
    render_inline(UI::Checkbox.new(name: "test", error: true))
    input = page.find("input[type='checkbox']")
    assert_equal "true", input["aria-invalid"]
    classes = input[:class].split
    assert_includes classes, "border-destructive"
  end

  def test_required_sets_required_attribute
    render_inline(UI::Checkbox.new(name: "test", required: true))
    input = page.find("input[required]")
    assert input["required"].present?
  end

  def test_label_renders_label_element_with_for_id
    render_inline(UI::Checkbox.new(name: "terms", label: "Accept terms"))
    label_el = page.find("label")
    input_el = page.find("input[type='checkbox']")
    assert label_el["for"].present?, "label should have for attribute"
    assert_equal label_el["for"], input_el[:id]
    assert_match(/Accept terms/, label_el.text)
  end

  def test_without_label_no_label_element_renders
    render_inline(UI::Checkbox.new(name: "test"))
    refute_selector "label"
  end

  def test_check_overlay_span_present_with_peer_checked_class
    render_inline(UI::Checkbox.new(name: "test"))
    wrapper = page.find(".relative.inline-flex")
    overlay = wrapper.find("span.pointer-events-none")
    classes = overlay[:class].split
    assert_includes classes, "peer-checked:opacity-100"
    assert_includes classes, "opacity-0"
  end

  def test_check_icon_inside_overlay
    render_inline(UI::Checkbox.new(name: "test"))
    overlay = page.find("span.pointer-events-none")
    icon = overlay.find("i", visible: :all)
    assert_equal "check", icon["data-lucide"]
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::Checkbox.new(name: "test", class: "border-red-500"))
    input = page.find("input[type='checkbox']")
    classes = input[:class].split
    refute_includes classes, "border-input"
    assert_includes classes, "border-red-500"
  end

  def test_name_and_id_passthrough
    render_inline(UI::Checkbox.new(name: "user[agree]", id: "agree-cb"))
    input = page.find("input#agree-cb[name='user[agree]']")
    assert input.present?
  end

  def test_data_attributes_passthrough
    render_inline(UI::Checkbox.new(name: "test", data: { test_id: "my-cb" }))
    assert_selector "input[data-test-id='my-cb']"
  end

  def test_size_sm_renders_smaller_box
    render_inline(UI::Checkbox.new(name: "test", size: :sm))
    classes = page.find("input[type='checkbox']")[:class].split
    assert_includes classes, "w-3.5"
    assert_includes classes, "h-3.5"
  end

  def test_size_lg_renders_larger_box
    render_inline(UI::Checkbox.new(name: "test", size: :lg))
    classes = page.find("input[type='checkbox']")[:class].split
    assert_includes classes, "w-5"
    assert_includes classes, "h-5"
  end

  def test_auto_generated_id_when_label_present
    render_inline(UI::Checkbox.new(name: "test", label: "Label"))
    input = page.find("input[type='checkbox']")
    assert input[:id].present?, "id should be auto-generated when label is provided"
    assert input[:id].start_with?("ui-cb-"), "id should start with ui-cb-"
  end

  def test_disabled_and_checked_combined
    render_inline(UI::Checkbox.new(name: "test", disabled: true, checked: true))
    input = page.find("input[disabled]")
    assert input["checked"].present?
  end

  def test_label_text_span_uses_correct_classes
    render_inline(UI::Checkbox.new(name: "test", label: "Terms"))
    label_el = page.find("label")
    span = label_el.all("span").find { |s| s.text.strip == "Terms" }
    assert span, "label text span should exist"
    classes = span[:class].split
    assert_includes classes, "text-sm"
    assert_includes classes, "leading-none"
  end

  def test_required_label_shows_styled_asterisk_span
    render_inline(UI::Checkbox.new(name: "test", label: "Agree", required: true))
    label_el = page.find("label")
    assert_match(/Agree/, label_el.text)
    asterisk = label_el.find("span.text-destructive")
    assert_match(/\*/, asterisk.text)
    classes = asterisk[:class].split
    assert_includes classes, "text-destructive"
    assert_includes classes, "ml-0.5"
  end

  def test_non_required_label_has_no_destructive_span
    render_inline(UI::Checkbox.new(name: "test", label: "Agree", required: false))
    refute_selector "label span.text-destructive"
  end

  def test_disabled_box_has_no_redundant_opacity_class
    render_inline(UI::Checkbox.new(name: "test", disabled: true, label: "x"))
    classes = page.find("input[type='checkbox']")[:class].split
    # Wrapper owns the dimming via opacity-60; box should not double-dim.
    refute_includes classes, "disabled:opacity-50"
    refute_includes classes, "disabled:opacity-50!"
    refute_includes classes, "disabled:cursor-not-allowed"
    refute_includes classes, "disabled:cursor-not-allowed!"
  end

  # Radii scale with the box so the corners stay visually consistent.
  def test_size_sm_radius
    render_inline(UI::Checkbox.new(name: "test", size: :sm))
    assert_includes page.find("input[type='checkbox']")[:class].split, "rounded-[3px]"
  end

  def test_size_default_radius
    render_inline(UI::Checkbox.new(name: "test", size: :default))
    assert_includes page.find("input[type='checkbox']")[:class].split, "rounded-[4px]"
  end

  def test_size_lg_radius
    render_inline(UI::Checkbox.new(name: "test", size: :lg))
    assert_includes page.find("input[type='checkbox']")[:class].split, "rounded-[5px]"
  end

  # --- form-builder binding + automatic labels (Rails convention) ---

  # Stands in for an app model: the builder needs only a name and attributes.
  class User
    include ActiveModel::Model
    attr_accessor :email, :password, :remember_me
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:user, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_scopes_the_field_name
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me))
    assert_selector "input[type='checkbox'][name='user[remember_me]']", visible: :all
  end

  def test_label_is_derived_from_the_attribute_name
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me))
    assert_text "Remember me"
  end

  def test_derived_label_is_associated_with_the_input
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me))
    assert_equal page.find("label")[:for],
                 page.find("input[type='checkbox']", visible: :all)[:id]
  end

  # Rails' check_box emits the companion hidden field so an unchecked box still
  # submits a value; the plain `name:` path has no such helper.
  def test_form_binding_emits_the_unchecked_companion_field
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me))
    hidden = page.find("input[type='hidden'][name='user[remember_me]']", visible: :all)
    assert_equal "0", hidden[:value]
  end

  def test_explicit_label_overrides_the_derived_one
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me, label: "Keep me signed in"))
    assert_text "Keep me signed in"
  end

  def test_label_false_opts_out
    render_inline(UI::Checkbox.new(form: form_builder_for(User.new), field: :remember_me, label: false))
    assert_no_selector "label"
  end

  def test_error_message_shows_under_the_box_and_describes_it
    render_inline(UI::Checkbox.new(name: "terms", label: "I accept the terms", id: "terms", error: "You must accept the terms"))
    box = page.find("input#terms[aria-invalid='true']")
    assert_equal "terms-error", box["aria-describedby"]
    assert_selector "div > label + p#terms-error.text-destructive", text: "You must accept the terms"
  end

  def test_model_errors_show_under_a_bound_checkbox
    record = Struct.new(:terms) do
      include ActiveModel::Validations
      def self.model_name = ActiveModel::Name.new(self, nil, "Signup")
      validates :terms, acceptance: { accept: "1" }
    end.new("0").tap(&:validate)
    form = ActionView::Helpers::FormBuilder.new(:signup, record, vc_test_controller.view_context, {})
    render_inline(UI::Checkbox.new(form: form, field: :terms))
    assert_selector "input[type='checkbox'][aria-invalid='true']"
    assert_selector "p.text-destructive", text: "Terms must be accepted"
  end

  def test_no_messages_no_wrapper
    render_inline(UI::Checkbox.new(name: "terms", label: "Terms"))
    refute_selector "div"
  end
end

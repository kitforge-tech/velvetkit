# frozen_string_literal: true

require "test_helper"

class UI::PasswordInputTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_a_masked_input_inside_an_input_group
    render_inline(UI::PasswordInput.new(name: "user[password]"))
    assert_selector "[data-slot='input-group']"
    assert_selector "input[type='password'][name='user[password]']"
  end

  def test_wires_the_stimulus_controller_and_input_target
    render_inline(UI::PasswordInput.new(name: "user[password]"))
    assert_selector "[data-controller='ui--password-visibility']"
    assert_selector "input[data-ui--password-visibility-target='input']"
  end

  def test_toggle_button_wires_action_and_accessible_name
    render_inline(UI::PasswordInput.new(name: "user[password]"))
    button = page.find("button[data-ui--password-visibility-target='toggle']")
    assert_includes button[:"data-action"], "ui--password-visibility#toggle"
    assert_equal "Show password", button[:"aria-label"]
    assert_equal "false", button[:"aria-pressed"]
  end

  def test_renders_both_toggle_icons_with_hide_hidden_initially
    render_inline(UI::PasswordInput.new(name: "user[password]"))
    assert_selector "span[data-ui--password-visibility-target='iconShow']"
    hide = page.find("span[data-ui--password-visibility-target='iconHide']", visible: :all)
    assert_includes hide[:style].to_s, "display: none"
  end

  def test_required_and_disabled_pass_through
    render_inline(UI::PasswordInput.new(name: "user[password]", required: true, disabled: true))
    input = page.find("input[type='password']", visible: :all)
    assert input[:required].present?
    assert input[:disabled].present?
  end

  # Velvet hardcoded a placeholder in its template, shadowing the caller's.
  def test_caller_placeholder_is_not_overridden
    render_inline(UI::PasswordInput.new(name: "user[password]", placeholder: "Your secret"))
    assert_equal "Your secret", page.find("input[type='password']")[:placeholder]
  end

  def test_no_placeholder_by_default
    render_inline(UI::PasswordInput.new(name: "user[password]"))
    assert_nil page.find("input[type='password']")[:placeholder].presence
  end

  def test_error_state_marks_input_invalid
    render_inline(UI::PasswordInput.new(name: "user[password]", error: true))
    assert_equal "true", page.find("input[type='password']")[:"aria-invalid"]
  end

  def test_user_class_reaches_the_group_wrapper
    render_inline(UI::PasswordInput.new(name: "user[password]", class: "mt-4"))
    assert_includes page.find("[data-slot='input-group']")[:class].split, "mt-4"
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
    render_inline(UI::PasswordInput.new(form: form_builder_for(User.new), field: :password))
    assert_selector "input[name='user[password]'][type='password']"
  end

  def test_label_is_derived_from_the_attribute_name
    render_inline(UI::PasswordInput.new(form: form_builder_for(User.new), field: :password))
    assert_selector "label", text: "Password"
  end

  # The input sits inside the group's border, so the label must render outside
  # it while still pointing at the field.
  def test_derived_label_sits_outside_the_group_and_is_associated
    render_inline(UI::PasswordInput.new(form: form_builder_for(User.new), field: :password))
    assert_equal page.find("label")[:for], page.find("input[type='password']")[:id]
    assert_no_selector "[data-slot='input-group'] label"
  end

  def test_label_false_opts_out
    render_inline(UI::PasswordInput.new(form: form_builder_for(User.new), field: :password, label: false))
    assert_no_selector "label"
  end

  def test_hint_and_error_sit_outside_the_group_and_describe_the_input
    render_inline(UI::PasswordInput.new(label: "Password", id: "pw", hint: "At least 12 characters", error: "Too short"))
    input = page.find("input#pw[aria-invalid='true']")
    assert_equal "pw-hint pw-error", input["aria-describedby"]
    assert_selector "p#pw-hint", text: "At least 12 characters"
    assert_selector "p#pw-error", text: "Too short"
    assert_selector "p", count: 2
  end
end

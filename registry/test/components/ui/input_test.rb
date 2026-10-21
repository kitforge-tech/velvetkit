# frozen_string_literal: true

require "test_helper"

class UI::InputTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  # ── Default render ───────────────────────────────────────────────────────────

  def test_renders_input_tag
    render_inline(UI::Input.new)
    assert_selector "input"
    refute_selector "div"
  end

  def test_default_type_is_text
    render_inline(UI::Input.new)
    assert_selector "input[type='text']"
  end

  def test_default_size_classes_present
    render_inline(UI::Input.new)
    inp = page.find("input")
    assert_includes inp[:class], "h-9"
  end

  def test_default_has_border_and_background
    render_inline(UI::Input.new)
    inp = page.find("input")
    assert_includes inp[:class], "border-input"
    assert_includes inp[:class], "bg-background"
  end

  # ── Type variants ────────────────────────────────────────────────────────────

  def test_type_email
    render_inline(UI::Input.new(type: :email))
    assert_selector "input[type='email']"
  end

  def test_type_password
    render_inline(UI::Input.new(type: :password))
    assert_selector "input[type='password']"
  end

  def test_type_number
    render_inline(UI::Input.new(type: :number))
    assert_selector "input[type='number']"
  end

  def test_type_search
    render_inline(UI::Input.new(type: :search))
    assert_selector "input[type='search']"
  end

  # ── Size variants ────────────────────────────────────────────────────────────

  def test_size_sm
    render_inline(UI::Input.new(size: :sm))
    inp = page.find("input")
    classes = inp[:class].split
    assert_includes classes, "h-8"
    assert_includes classes, "text-xs"
  end

  def test_size_default
    render_inline(UI::Input.new(size: :default))
    assert_selector "input.h-9"
  end

  def test_size_lg
    render_inline(UI::Input.new(size: :lg))
    inp = page.find("input")
    assert_includes inp[:class], "h-10"
  end

  # ── Error / invalid state ────────────────────────────────────────────────────

  def test_error_state_sets_aria_invalid
    render_inline(UI::Input.new(error: true, variant: :error))
    assert_selector "input[aria-invalid='true']"
  end

  def test_error_state_adds_destructive_ring_class
    render_inline(UI::Input.new(variant: :error))
    inp = page.find("input")
    assert_includes inp[:class], "border-destructive"
  end

  def test_no_error_does_not_set_aria_invalid
    render_inline(UI::Input.new)
    refute_selector "input[aria-invalid]"
  end

  # ── Disabled state ───────────────────────────────────────────────────────────

  def test_disabled_sets_html_disabled
    render_inline(UI::Input.new(disabled: true))
    assert_selector "input[disabled]"
  end

  def test_disabled_adds_cursor_class
    render_inline(UI::Input.new(disabled: true))
    inp = page.find("input[disabled]")
    assert_includes inp[:class], "disabled:cursor-not-allowed"
  end

  # ── Placeholder ──────────────────────────────────────────────────────────────

  def test_placeholder_passes_through
    render_inline(UI::Input.new(placeholder: "Enter email…"))
    assert_selector "input[placeholder='Enter email…']"
  end

  # ── Name / id / value ────────────────────────────────────────────────────────

  def test_name_and_id_pass_through
    render_inline(UI::Input.new(name: "user[email]", id: "user_email"))
    assert_selector "input#user_email[name='user[email]']"
  end

  def test_value_passes_through
    render_inline(UI::Input.new(value: "hello@example.com"))
    assert_selector "input[value='hello@example.com']"
  end

  # ── User-class merge ─────────────────────────────────────────────────────────

  def test_user_class_merges_via_tailwind_merge
    render_inline(UI::Input.new(class: "bg-red-100"))
    inp = page.find("input")
    classes = inp[:class].split
    refute_includes classes, "bg-background"
    assert_includes classes, "bg-red-100"
  end

  # ── Arbitrary html_attrs ─────────────────────────────────────────────────────

  def test_html_attrs_pass_through
    render_inline(UI::Input.new(id: "q", data: { test_id: "search" }))
    assert_selector "input#q[data-test-id='search']"
  end

  def test_autocomplete_passes_through
    render_inline(UI::Input.new(autocomplete: "email"))
    assert_selector "input[autocomplete='email']"
  end

  # ── Label ────────────────────────────────────────────────────────────────────

  def test_label_renders_label_element_as_sibling_of_input
    render_inline(UI::Input.new(label: "Email"))
    assert_selector "label", text: "Email"
    # input must be a sibling, not a descendant
    assert_selector "div > label + input"
    refute_selector "label > input"
  end

  def test_label_for_attribute_links_to_input_id
    render_inline(UI::Input.new(label: "Email"))
    label = page.find("label")
    input = page.find("input")
    assert_equal input[:id], label[:for]
    assert input[:id].to_s.start_with?("ui-input-")
  end

  def test_explicit_id_is_preserved_and_linked
    render_inline(UI::Input.new(label: "Email", id: "user_email"))
    assert_selector "label[for='user_email']"
    assert_selector "input#user_email"
  end

  def test_label_with_size_variant
    render_inline(UI::Input.new(label: "Email", label_size: :sm))
    label = page.find("label")
    assert_includes label[:class], "text-sm"
  end

  def test_required_label_shows_styled_asterisk_span
    render_inline(UI::Input.new(label: "Email", required: true))
    assert_selector "label", text: "Email *"
    asterisk = page.find("label span.text-destructive")
    assert_match(/\*/, asterisk.text)
  end

  def test_required_sets_html_required_on_input
    render_inline(UI::Input.new(label: "Email", required: true))
    assert_selector "input[required]"
  end

  def test_required_without_label_still_sets_html_required
    render_inline(UI::Input.new(required: true))
    assert_selector "input[required]"
  end

  def test_non_required_label_no_asterisk
    render_inline(UI::Input.new(label: "Email"))
    assert_selector "label", text: "Email"
    refute_selector "label span.text-destructive"
    refute_selector "input[required]"
  end

  def test_disabled_input_with_label_propagates_disabled_to_label
    render_inline(UI::Input.new(label: "Email", disabled: true))
    label = page.find("label")
    assert_includes label[:class], "text-muted-foreground"
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
    render_inline(UI::Input.new(form: form_builder_for(User.new), field: :email, type: :email))
    assert_selector "input[name='user[email]'][type='email']"
  end

  def test_label_is_derived_from_the_attribute_name
    render_inline(UI::Input.new(form: form_builder_for(User.new), field: :email, type: :email))
    assert_selector "label", text: "Email"
  end

  def test_derived_label_is_associated_with_the_input
    render_inline(UI::Input.new(form: form_builder_for(User.new), field: :email, type: :email))
    assert_equal page.find("label")[:for], page.find("input")[:id]
  end

  def test_explicit_label_overrides_the_derived_one
    render_inline(UI::Input.new(form: form_builder_for(User.new), field: :email, label: "Work email"))
    assert_selector "label", text: "Work email"
  end

  def test_label_false_opts_out
    render_inline(UI::Input.new(form: form_builder_for(User.new), field: :email, label: false))
    assert_no_selector "label"
  end

  def test_no_label_without_a_form_binding
    render_inline(UI::Input.new(name: "user[email]"))
    assert_no_selector "label"
  end
end

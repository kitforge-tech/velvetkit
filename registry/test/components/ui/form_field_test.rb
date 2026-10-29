# frozen_string_literal: true

require "test_helper"

class UI::FormFieldTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  class Account
    include ActiveModel::Model
    attr_accessor :email, :name
    validates :email, presence: true
    validates :email, format: { with: /@/ }, allow_blank: true
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:account, record, vc_test_controller.view_context, {})
  end

  def invalid_account
    Account.new.tap(&:validate)
  end

  # ── Wrapping ─────────────────────────────────────────────────────────────────

  def test_nothing_to_show_renders_the_control_alone
    render_inline(UI::FormField.new) { "<input id='x'>".html_safe }
    assert_selector "input#x"
    refute_selector "div"
  end

  def test_label_hint_and_error_wrap_the_control
    render_inline(UI::FormField.new(label: "Colour", hint: "For your avatar", error: "Pick a colour", for: "colour")) do
      "<input id='colour'>".html_safe
    end
    assert_selector "div > label[for='colour'] + input#colour + p#colour-hint + p#colour-error"
    assert_selector "p#colour-hint.text-muted-foreground", text: "For your avatar"
    assert_selector "p#colour-error.text-destructive", text: "Pick a colour"
  end

  def test_block_receives_the_field_for_custom_controls
    render_inline(UI::FormField.new(label: "Colour", hint: "For your avatar", error: "Pick a colour")) do |field|
      ActionController::Base.helpers.tag.input(type: "color", **field.control_attributes)
    end
    input = page.find("input[type='color']")
    assert_equal page.find("label")[:for], input[:id]
    assert input[:id].start_with?("ui-field-")
    assert_equal "#{input[:id]}-hint #{input[:id]}-error", input["aria-describedby"]
    assert_equal "true", input["aria-invalid"]
  end

  def test_user_class_and_attrs_on_the_wrapper
    render_inline(UI::FormField.new(label: "Name", class: "max-w-sm", data: { test_id: "f" })) { "x" }
    wrapper = page.find("div[data-test-id='f']")
    assert_includes wrapper[:class].split, "max-w-sm"
    assert_includes wrapper[:class].split, "gap-2"
  end

  # ── Error states ─────────────────────────────────────────────────────────────

  def test_error_true_is_invalid_without_a_message
    field = UI::FormField.new(error: true)
    assert field.error?
    assert_nil field.error_message
    refute field.wrap?
  end

  def test_no_hint_or_error_no_describedby
    field = UI::FormField.new(label: "Name")
    assert_nil field.describedby
    assert_equal({ id: field.control_id }, field.control_attributes)
  end

  # ── Form binding ─────────────────────────────────────────────────────────────

  def test_model_errors_become_the_message
    field = UI::FormField.new(form: form_builder_for(invalid_account), field: :email)
    assert field.error?
    assert_equal "Email can't be blank", field.error_message
  end

  def test_several_model_errors_join_into_one_sentence
    account = Account.new(email: "nope")
    account.errors.add(:email, :taken)
    account.validate
    account.errors.add(:email, "is reserved")
    field = UI::FormField.new(form: form_builder_for(account), field: :email)
    assert_equal "Email is invalid and Email is reserved", field.error_message
  end

  def test_a_foreign_key_field_shows_its_association_errors
    account = Account.new
    account.errors.add(:team, "must exist")
    field = UI::FormField.new(form: form_builder_for(account), field: :team_id)
    assert_equal "Team must exist", field.error_message
  end

  def test_no_model_errors_no_message
    field = UI::FormField.new(form: form_builder_for(Account.new(email: "a@b.c")), field: :email)
    refute field.error?
  end

  def test_explicit_error_wins_over_model_errors
    field = UI::FormField.new(form: form_builder_for(invalid_account), field: :email, error: "Use your work email")
    assert_equal "Use your work email", field.error_message
  end

  def test_error_false_ignores_model_errors
    field = UI::FormField.new(form: form_builder_for(invalid_account), field: :email, error: false)
    refute field.error?
  end

  def test_form_without_a_model_has_no_errors
    builder = ActionView::Helpers::FormBuilder.new(:search, nil, vc_test_controller.view_context, {})
    refute UI::FormField.new(form: builder, field: :q).error?
  end

  def test_label_comes_from_the_attribute
    render_inline(UI::FormField.new(form: form_builder_for(Account.new), field: :name)) { "x" }
    assert_selector "label", text: "Name"
  end
end

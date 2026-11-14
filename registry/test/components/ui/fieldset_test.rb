# frozen_string_literal: true

require "test_helper"

class UI::FieldsetTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  Settings = Struct.new(:channels) do
    include ActiveModel::Validations
    def self.model_name = ActiveModel::Name.new(self, nil, "Settings")
    validates :channels, presence: true
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:settings, record, vc_test_controller.view_context, {})
  end

  def test_renders_a_fieldset_named_by_its_legend
    render_inline(UI::Fieldset.new(legend: "Notifications", id: "notify")) { "controls" }
    assert_selector "fieldset#notify[aria-labelledby='notify-legend']", text: "controls"
    assert_selector "fieldset > legend#notify-legend:first-child", text: "Notifications"
  end

  def test_hint_and_error_describe_the_group
    render_inline(UI::Fieldset.new(legend: "Plan", hint: "Change it any time.", error: "Choose a plan", id: "plan"))
    assert_selector "fieldset[aria-describedby='plan-hint plan-error']"
    assert_selector "p#plan-hint", text: "Change it any time."
    assert_selector "p#plan-error.text-destructive", text: "Choose a plan"
  end

  def test_hint_comes_before_the_controls_and_the_error_after
    render_inline(UI::Fieldset.new(legend: "Plan", hint: "Hint", error: "Error")) { "<span>controls</span>".html_safe }
    assert_equal %w[legend p span p], page.all("fieldset > *").map(&:tag_name)
  end

  def test_makes_an_id_when_given_none
    render_inline(UI::Fieldset.new(legend: "Plan", hint: "Hint"))
    id = page.find("fieldset")[:id]
    assert id.start_with?("ui-fieldset-")
    assert_selector "legend##{id}-legend"
    assert_selector "p##{id}-hint"
  end

  def test_nothing_to_describe_means_no_aria_describedby
    render_inline(UI::Fieldset.new(legend: "Plan"))
    assert_no_selector "fieldset[aria-describedby]"
    assert_no_selector "p"
  end

  def test_required_marks_the_legend
    render_inline(UI::Fieldset.new(legend: "Plan", required: true))
    assert_selector "legend span.text-destructive", text: "*"
  end

  def test_disabled_disables_the_fieldset
    render_inline(UI::Fieldset.new(legend: "Plan", disabled: true))
    assert_selector "fieldset[disabled]"
    assert_selector "legend.text-muted-foreground"
  end

  def test_a_plain_group_takes_no_required_or_invalid
    render_inline(UI::Fieldset.new(legend: "Plan", required: true, error: "Choose one"))
    assert_no_selector "fieldset[aria-required]"
    assert_no_selector "fieldset[aria-invalid]"
  end

  def test_a_radiogroup_is_required_and_invalid
    render_inline(UI::Fieldset.new(legend: "Plan", required: true, error: true, role: "radiogroup"))
    assert_selector "fieldset[role='radiogroup'][aria-required='true'][aria-invalid='true']"
    assert_no_selector "p.text-destructive"
  end

  def test_wrap_only_with_something_to_show
    assert UI::Fieldset.new(legend: "Plan").wrap?
    assert UI::Fieldset.new(legend: false, hint: "Hint").wrap?
    assert UI::Fieldset.new(legend: false, error: "Error").wrap?
    refute UI::Fieldset.new(legend: false).wrap?
    refute UI::Fieldset.new.wrap?
  end

  def test_form_binding_names_it_and_shows_the_models_errors
    render_inline(UI::Fieldset.new(form: form_builder_for(Settings.new([]).tap(&:validate)), field: :channels, id: "ch"))
    assert_selector "legend", text: "Channels"
    assert_selector "p#ch-error", text: "Channels can't be blank"
  end

  def test_legend_overrides_the_attribute_name_and_false_drops_it
    form = form_builder_for(Settings.new([]))
    render_inline(UI::Fieldset.new(form: form, field: :channels, legend: "Where to notify you"))
    assert_selector "legend", text: "Where to notify you"
    render_inline(UI::Fieldset.new(form: form, field: :channels, legend: false))
    assert_no_selector "legend"
  end

  def test_user_class_and_attrs_pass_through
    render_inline(UI::Fieldset.new(legend: "Plan", class: "gap-6", data: { testid: "plan" }, aria: { label: "Billing plan" }))
    fieldset = page.find("fieldset[data-testid='plan'][aria-label='Billing plan']")
    assert_includes fieldset[:class].split, "gap-6"
    refute_includes fieldset[:class].split, "gap-3"
    assert fieldset[:"aria-labelledby"].present?
  end
end

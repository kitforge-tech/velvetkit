# frozen_string_literal: true

require "test_helper"

class UI::RadioGroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_radiogroup_role
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free") { "Free" }
    end
    assert_selector "[role='radiogroup']"
  end

  def test_auto_generates_id
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    rg = page.find("[role='radiogroup']")
    assert rg[:id].present?
    assert rg[:id].start_with?("ui-rg-")
  end

  def test_user_class_passthrough
    render_inline(UI::RadioGroup.new(name: "plan", class: "gap-4")) { "" }
    classes = page.find("[role='radiogroup']")[:class].split
    assert_includes classes, "gap-4"
    assert_includes classes, "flex"
    assert_includes classes, "flex-col"
  end

  def test_html_attrs_passthrough
    render_inline(UI::RadioGroup.new(name: "plan", data: { test_id: "rg-x" })) { "" }
    assert_selector "[role='radiogroup'][data-test-id='rg-x']"
  end

  def test_renders_items
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    assert_equal 2, inputs.size
  end

  def test_items_share_same_name
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
      rg.with_item(value: "pro")
    end
    inputs = page.all("input[type='radio']")
    assert_equal "plan", inputs.first[:name]
    assert_equal "plan", inputs.last[:name]
  end

  def test_checked_item_reflects_group_value
    render_inline(UI::RadioGroup.new(name: "plan", value: "pro")) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    refute inputs.first["checked"].present?
    assert inputs.last["checked"].present?
  end

  def test_item_label_renders_with_for_id
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free plan")
    end
    label_el = page.find("label")
    input_el = page.find("input[type='radio']")
    assert_equal label_el["for"], input_el[:id]
    assert_match(/Free plan/, label_el.text)
  end

  def test_item_without_label_no_label_element
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    refute_selector "label"
  end

  def test_disabled_group_disables_all_items
    render_inline(UI::RadioGroup.new(name: "plan", disabled: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    inputs.each { |i| assert i.disabled? }
  end

  def test_required_group_sets_required_on_items
    render_inline(UI::RadioGroup.new(name: "plan", required: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    inputs.each { |i| assert i["required"].present? }
  end

  def test_required_label_shows_asterisk
    render_inline(UI::RadioGroup.new(name: "plan", required: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
    end
    label_el = page.find("label")
    assert_match(/Free \*/, label_el.text)
  end

  def test_disabled_item_wrapper_dims
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free", disabled: true)
    end
    label_el = page.find("label")
    classes = label_el[:class].split
    assert_includes classes, "cursor-not-allowed"
    assert_includes classes, "opacity-60"
  end

  def test_item_dot_appears_when_checked
    render_inline(UI::RadioGroup.new(name: "plan", value: "pro")) do |rg|
      rg.with_item(value: "pro", label: "Pro")
    end
    input = page.find("input[type='radio'][checked]")
    dot = page.find("span.rounded-full.bg-primary-foreground", visible: :all)
    classes = dot[:class].split
    assert_includes classes, "bg-primary-foreground"
  end

  def test_item_box_has_rounded_full_and_checked_states
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    classes = page.find("input[type='radio']")[:class].split
    assert_includes classes, "rounded-full"
    assert_includes classes, "peer"
    assert_includes classes, "appearance-none"
  end

  Account = Struct.new(:plan, :seats) do
    include ActiveModel::Validations
    def self.model_name = ActiveModel::Name.new(self, nil, "Account")
    validates :plan, presence: true
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:account, record, vc_test_controller.view_context, {})
  end

  def test_a_legend_makes_the_fieldset_the_radiogroup
    render_inline(UI::RadioGroup.new(name: "plan", legend: "Plan", hint: "Change it any time.", required: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
    end
    fieldset = page.find("fieldset[role='radiogroup'][aria-required='true']")
    assert_equal "#{fieldset[:id]}-legend", fieldset[:"aria-labelledby"]
    assert_equal "#{fieldset[:id]}-hint", fieldset[:"aria-describedby"]
    assert_selector "legend", text: "Plan"
    assert_selector "[role='radiogroup']", count: 1
    assert_selector "fieldset > div.flex-col input[type='radio'][name='plan'][required]"
    assert_selector "span.text-destructive", text: "*", count: 1
  end

  def test_without_a_legend_hint_or_error_it_is_unchanged
    render_inline(UI::RadioGroup.new(name: "plan")) { |rg| rg.with_item(value: "free") }
    assert_no_selector "fieldset"
    assert_selector "div[role='radiogroup']"
  end

  def test_error_marks_the_group_invalid
    render_inline(UI::RadioGroup.new(name: "plan", legend: "Plan", error: "Choose a plan")) { |rg| rg.with_item(value: "free") }
    fieldset = page.find("fieldset[aria-invalid='true']")
    assert_selector "p##{fieldset[:id]}-error", text: "Choose a plan"
  end

  def test_class_and_attrs_stay_on_the_radios_container
    render_inline(UI::RadioGroup.new(name: "plan", legend: "Plan", id: "plans", class: "flex-row", data: { testid: "plans" })) do |rg|
      rg.with_item(value: "free")
    end
    assert_selector "fieldset > div#plans.flex-row[data-testid='plans']"
    assert_no_selector "fieldset[data-testid]"
  end

  def test_form_builder_names_and_values
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new("pro")), field: :plan)) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    assert_selector "input[name='account[plan]']", count: 2
    assert page.find("input[value='pro']").checked?
  end

  def test_values_compare_as_strings
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new(nil, 5)), field: :seats)) do |rg|
      rg.with_item(value: 5, label: "Five")
    end
    assert page.find("input[value='5']").checked?
  end

  def test_a_bound_group_shows_the_models_error_without_growing_a_legend
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new(nil).tap(&:validate)), field: :plan)) do |rg|
      rg.with_item(value: "free", label: "Free")
    end
    assert_selector "fieldset[role='radiogroup'][aria-invalid='true']"
    assert_selector "p.text-destructive", text: "Plan can't be blank"
    assert_no_selector "legend"
  end

  def test_renders_no_whitespace_around_itself
    render_inline(UI::RadioGroup.new(name: "plan")) { |rg| rg.with_item(value: "free") }
    assert rendered_content.start_with?("<div"), rendered_content[0, 20].inspect
    render_inline(UI::RadioGroup.new(name: "plan", legend: "Plan")) { |rg| rg.with_item(value: "free") }
    assert rendered_content.start_with?("<fieldset"), rendered_content[0, 20].inspect
  end

  def test_a_blank_legend_is_no_legend
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new("pro")), field: :plan, legend: "")) do |rg|
      rg.with_item(value: "free")
    end
    assert_no_selector "fieldset"
    assert_no_selector "legend"
  end

  def test_legend_true_uses_the_attribute_name
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new("pro")), field: :plan, legend: true)) do |rg|
      rg.with_item(value: "free")
    end
    assert_selector "legend", text: "Plan"
  end

  def test_your_aria_attributes_move_to_the_fieldset
    render_inline(UI::RadioGroup.new(name: "plan", hint: "Change it any time.", aria: { label: "Billing plan" })) do |rg|
      rg.with_item(value: "free")
    end
    assert_selector "fieldset[role='radiogroup'][aria-label='Billing plan']"
    assert_no_selector "div[aria-label]"
  end

  def test_error_false_hides_the_models_error
    render_inline(UI::RadioGroup.new(form: form_builder_for(Account.new(nil).tap(&:validate)), field: :plan, error: false)) do |rg|
      rg.with_item(value: "free")
    end
    assert_no_selector "fieldset"
    assert_selector "div[role='radiogroup']"
  end
end

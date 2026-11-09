# frozen_string_literal: true

require "test_helper"

class UI::MoneyInputTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_money(**opts) = render_inline(UI::MoneyInput.new(name: "amount", **opts))

  def field = page.find("input[data-ui--money-input-target='field']")
  def hidden = page.find("input[type='hidden'][data-ui--money-input-target='value']", visible: :all)

  def test_shows_the_amount_grouped_and_posts_it_plain
    render_money(value: 1_234_567.5, unit: "$")
    assert_equal "1,234,567.50", field.value
    assert_equal "1234567.50", hidden.value
    assert_equal "amount", hidden[:name]
    assert_nil field[:name]
  end

  def test_rupees_group_the_indian_way
    render_money(value: 12_345_678.9, unit: "₹")
    assert_equal "1,23,45,678.90", field.value
    assert_equal "12345678.90", hidden.value
  end

  def test_grouping_can_be_chosen
    render_money(value: 1_234_567, unit: "₹", grouping: :thousands)
    assert_equal "1,234,567.00", field.value
    render_money(value: 1_234_567, unit: "$", grouping: :indian)
    assert_equal "12,34,567.00", field.value
  end

  def test_small_amounts_are_not_grouped
    render_money(value: 999, unit: "₹")
    assert_equal "999.00", field.value
  end

  def test_a_typed_string_is_read_with_the_delimiters_in_it
    render_money(value: "1,23,456.789", unit: "₹")
    assert_equal "1,23,456.79", field.value
    assert_equal "123456.79", hidden.value
  end

  def test_large_amounts_keep_every_digit
    render_money(value: "123456789012345.67", unit: "$")
    assert_equal "123456789012345.67", hidden.value
  end

  def test_no_value_is_empty_with_a_zero_placeholder
    render_money(unit: "₹")
    assert_equal "", field.value.to_s
    assert_equal "0.00", field[:placeholder]
    assert_equal "", hidden.value.to_s
  end

  def test_precision_zero_is_whole_amounts
    render_money(value: 1500.6, unit: "¥", precision: 0)
    assert_equal "1,501", field.value
    assert_equal "1501", hidden.value
    assert_equal "0", field[:placeholder]
  end

  def test_locale_separators
    render_money(value: 1234.5, unit: "€", separator: ",", delimiter: ".")
    assert_equal "1.234,50", field.value
    assert_equal "1234.50", hidden.value
    assert_equal ",", root["data-ui--money-input-separator-value"]
    assert_equal ".", root["data-ui--money-input-delimiter-value"]
  end

  def test_negative_amounts_only_when_allowed
    render_money(value: -250)
    assert_equal "250.00", field.value
    render_money(value: -250, negative: true)
    assert_equal "-250.00", field.value
    assert_equal "-250.00", hidden.value
  end

  def test_sign_sits_where_the_locale_writes_it
    render_money(unit: "₹")
    assert_selector "[data-align='inline-start']", text: "₹"
    I18n.with_locale(:en) do
      I18n.backend.store_translations(:en, number: { currency: { format: { format: "%n %u" } } })
      render_money(unit: "kr")
      assert_selector "[data-align='inline-end']", text: "kr"
    ensure
      I18n.backend.store_translations(:en, number: { currency: { format: { format: "%u%n" } } })
    end
  end

  def test_the_field_is_a_decimal_text_field_wired_to_the_controller
    render_money
    assert_selector "[data-slot='money-input'][data-controller='ui--money-input']"
    assert_equal "text", field[:type]
    assert_equal "decimal", field[:inputmode]
    assert_equal "off", field[:autocomplete]
    assert_equal "beforeinput->ui--money-input#guard keydown->ui--money-input#nudge input->ui--money-input#type " \
                 "blur->ui--money-input#finish", field["data-action"]
    assert_equal "1", root["data-ui--money-input-step-value"]
  end

  def test_step_is_written_plainly_for_the_arrow_keys
    render_money(step: 0.5)
    assert_equal "0.5", root["data-ui--money-input-step-value"]
    render_money(step: 100)
    assert_equal "100", root["data-ui--money-input-step-value"]
  end

  def test_label_hint_and_error
    render_money(id: "amt", label: "Amount", hint: "Including GST", error: "Can't be blank", required: true)
    assert_selector "label[for='amt']", text: "Amount"
    assert_equal "amt-hint amt-error", field["aria-describedby"]
    assert_equal "true", field["aria-invalid"]
    assert field[:required]
  end

  def test_disabled_turns_off_both_fields
    render_money(value: 10, disabled: true)
    assert field[:disabled]
    assert hidden[:disabled]
  end

  def test_passes_attributes_to_the_field_and_class_to_the_root
    render_money(class: "max-w-xs", autofocus: true, data: { action: "change->cart#total" })
    assert_selector "[data-slot='money-input'].max-w-xs"
    assert field[:autofocus]
    assert_includes field["data-action"], "change->cart#total"
  end

  def root = page.find("[data-slot='money-input']")

  Invoice = Struct.new(:total) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Invoice")
    def persisted? = false
  end

  def test_form_binding_names_the_hidden_field_reads_the_value_and_derives_the_label
    form = ActionView::Helpers::FormBuilder.new(:invoice, Invoice.new(BigDecimal("4999.5")), vc_test_controller.view_context, {})
    render_inline(UI::MoneyInput.new(form: form, field: :total, unit: "₹"))
    assert_equal "invoice[total]", hidden[:name]
    assert_equal "4999.50", hidden.value
    assert_equal "4,999.50", field.value
    assert_selector "label[for='#{field[:id]}']", text: "Total"
  end
end

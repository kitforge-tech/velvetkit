# frozen_string_literal: true

require "test_helper"

class UI::ScanInputTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_scan(**opts) = render_inline(UI::ScanInput.new(name: "code", **opts))

  def field = page.find("input[data-ui--scan-input-target='field']")
  def group = page.find("[data-controller='ui--scan-input']")

  def test_renders_a_text_field_in_a_group_with_the_controller_and_an_icon
    render_scan
    assert_equal "ui--scan-input", group["data-controller"]
    assert_equal "text", field[:type]
    assert_equal "code", field[:name]
    assert_equal "keydown->ui--scan-input#key", field["data-action"]
    assert_selector "[data-align='inline-start'] svg"
  end

  def test_a_code_is_not_a_word
    render_scan
    assert_equal "off", field[:autocomplete]
    assert_equal "off", field[:autocapitalize]
    assert_equal "off", field[:autocorrect]
    assert_equal "false", field[:spellcheck]
    assert_equal "go", field[:enterkeyhint]
  end

  def test_focused_on_load_unless_told_not_to
    render_scan
    assert field[:autofocus]
    render_scan(autofocus: false)
    assert_nil field[:autofocus]
    render_scan(disabled: true)
    assert_nil field[:autofocus]
  end

  def test_defaults_submit_clear_and_keep_focus
    render_scan
    assert_equal "true", group["data-ui--scan-input-submit-value"]
    assert_equal "true", group["data-ui--scan-input-clear-value"]
    assert_equal "true", group["data-ui--scan-input-keep-focus-value"]
    assert_equal "false", group["data-ui--scan-input-capture-value"]
    assert_equal "enter", group["data-ui--scan-input-suffix-value"]
  end

  def test_options_reach_the_controller
    render_scan(submit: false, clear: false, keep_focus: false, capture: true, suffix: :tab)
    assert_equal "false", group["data-ui--scan-input-submit-value"]
    assert_equal "false", group["data-ui--scan-input-clear-value"]
    assert_equal "false", group["data-ui--scan-input-keep-focus-value"]
    assert_equal "true", group["data-ui--scan-input-capture-value"]
    assert_equal "tab", group["data-ui--scan-input-suffix-value"]
  end

  def test_an_unknown_suffix_is_enter
    render_scan(suffix: :space)
    assert_equal "enter", group["data-ui--scan-input-suffix-value"]
  end

  def test_keyboard_false_keeps_the_on_screen_keyboard_down
    render_scan
    assert_nil field[:inputmode]
    render_scan(keyboard: false)
    assert_equal "none", field[:inputmode]
  end

  def test_placeholder_defaults_and_can_be_set
    render_scan
    assert_equal "Scan or type a code", field[:placeholder]
    render_scan(placeholder: "Scan a ticket")
    assert_equal "Scan a ticket", field[:placeholder]
  end

  def test_label_hint_and_error
    render_scan(id: "sku", label: "Item", hint: "EAN or SKU", error: "Not found")
    assert_selector "label[for='sku']", text: "Item"
    assert_equal "sku-hint sku-error", field["aria-describedby"]
    assert_equal "true", field["aria-invalid"]
  end

  def test_sizes_and_class_go_on_the_group
    render_scan(size: :lg, class: "max-w-sm")
    assert_includes group[:class], "h-12"
    assert_includes group[:class], "max-w-sm"
  end

  def test_extra_actions_are_kept
    render_scan(data: { action: "input->lookup#search" })
    assert_equal "keydown->ui--scan-input#key input->lookup#search", field["data-action"]
  end

  Ticket = Struct.new(:code) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Ticket")
    def persisted? = false
  end

  def test_form_binding
    form = ActionView::Helpers::FormBuilder.new(:ticket, Ticket.new("QR-123"), vc_test_controller.view_context, {})
    render_inline(UI::ScanInput.new(form: form, field: :code))
    assert_equal "ticket[code]", field[:name]
    assert_equal "QR-123", field.value
    assert_selector "label[for='#{field[:id]}']", text: "Code"
  end
end

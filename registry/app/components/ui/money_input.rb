# frozen_string_literal: true

require "bigdecimal"
require "securerandom"

# An amount of money, written the way people read it: grouped as it's typed,
# with the currency sign beside it and the paise or cents filled in when the
# field is left. The form gets the plain number.
#
#   <%= render(UI::MoneyInput.new(name: "amount", value: 123456.5, unit: "₹", label: "Amount")) %>
#   <%= render(UI::MoneyInput.new(form: f, field: :price)) %>
#
# The reader sees "1,23,456.50"; a hidden field posts "123456.50", so the
# controller never has to strip commas. Typing anything but digits and one
# decimal point is ignored, a pasted "₹1,23,456.789" is cleaned up, and no
# more decimals than `precision:` can be typed. It's a text field with the
# decimal keypad on phones, not type="number", which can't show grouping.
#
# The sign, separator, delimiter, precision and the sign's side come from the
# app's locale (`number.currency.format`), so each can be left out. `unit: "₹"`
# groups the Indian way (1,23,45,678) unless `grouping: :thousands` says
# otherwise; `grouping: :indian` asks for it with any sign. `precision: 0` is
# for whole amounts. Amounts can't be negative unless `negative: true`.
#
# ↑ and ↓ add or take away one whole unit, or `step:` (0.5, 100), and Shift
# ten of them. Each press fires `input` and `change`, as a number field does.
#
# It takes the same label, hint, error, size and form-builder options as
# UI::NumberInput. The visible field fires `input` and `change` as usual; read
# the amount from the hidden field (`[data-ui--money-input-target=value]`).
class UI::MoneyInput < UI::Base
  SIZES = {
    sm:      "h-8 [&>input]:h-full [&>input]:text-xs",
    default: "h-9",
    lg:      "h-12 [&>input]:h-full [&>input]:text-base"
  }.freeze

  GROUPINGS = %i[thousands indian].freeze

  def initialize(name: nil, value: nil, form: nil, field: nil, unit: nil, precision: nil, separator: nil,
                 delimiter: nil, grouping: nil, negative: false, step: 1, size: :default, label: nil, hint: nil,
                 error: nil, required: false, disabled: false, placeholder: nil, class: nil, **html_attrs)
    @name        = name
    @form        = form
    @field       = field
    @unit        = unit || currency(:unit, "$")
    @precision   = Integer(precision || currency(:precision, 2))
    @separator   = separator || currency(:separator, ".")
    @delimiter   = delimiter || currency(:delimiter, ",")
    @grouping    = GROUPINGS.include?(grouping&.to_sym) ? grouping.to_sym : (@unit == "₹" ? :indian : :thousands)
    @negative    = negative
    @step        = step
    @size        = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @required    = required
    @disabled    = disabled
    @placeholder = placeholder
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
    @input_id    = html_attrs.delete(:id) || "ui-money-input-#{SecureRandom.hex(4)}"
    @amount      = amount(bound || value)
    @wrapper     = UI::FormField.new(label: label, hint: hint, error: error, required: required, disabled: disabled,
                                     form: form, field: field, for: @input_id)
  end

  attr_reader :wrapper

  def root_attrs
    { class: cn("w-full", @user_class),
      data: { slot: "money-input", controller: "ui--money-input", "ui--money-input-separator-value": @separator,
              "ui--money-input-delimiter-value": @delimiter, "ui--money-input-precision-value": @precision,
              "ui--money-input-grouping-value": @grouping, "ui--money-input-negative-value": @negative,
              "ui--money-input-step-value": BigDecimal(@step.to_s).to_s("F").delete_suffix(".0") } }
  end

  def group_component
    UI::InputGroup.new(class: cn("[&>input]:tabular-nums", SIZES[@size]),
                       data: { disabled: (true if @disabled) }.compact)
  end

  def field_options
    data = @html_attrs[:data] || {}
    action = [ "beforeinput->ui--money-input#guard keydown->ui--money-input#nudge input->ui--money-input#type " \
             "blur->ui--money-input#finish", data[:action] ].compact.join(" ")
    { type: :text, inputmode: "decimal", autocomplete: "off", spellcheck: false, value: shown,
      placeholder: @placeholder || shown(BigDecimal(0)), required: @required, disabled: @disabled,
      error: wrapper.error?, "aria-describedby": wrapper.describedby, **@html_attrs, id: @input_id,
      data: data.merge("ui--money-input-target": "field", action: action) }.compact
  end

  def hidden_attrs
    { type: "hidden", name: hidden_name, value: plain, disabled: (true if @disabled),
      data: { "ui--money-input-target": "value" } }.compact
  end

  def unit = @unit

  # The sign goes where the locale writes it: "%u%n" before, "%n %u" after.
  def unit_align
    pattern = currency(:format, "%u%n")
    pattern.index("%u").to_i > pattern.index("%n").to_i ? "inline-end" : "inline-start"
  end

  # What the reader sees: "1,23,456.50".
  def shown(amount = @amount) = written(amount, @separator) { |whole| group(whole) }

  # What the form posts: "123456.50". Built from the digits, never a float.
  def plain = written(@amount, ".").to_s

  private

  def written(amount, separator)
    return nil if amount.nil?

    whole, fraction = amount.abs.to_s("F").split(".")
    text = block_given? ? yield(whole) : whole
    text += separator + fraction.to_s.ljust(@precision, "0")[0, @precision] if @precision.positive?
    amount.negative? ? "-#{text}" : text
  end

  def currency(key, default) = I18n.t("number.currency.format.#{key}", default: default)

  def hidden_name
    return "#{@form.object_name}[#{@field}]" if @form && @field

    @name
  end

  def bound
    return nil unless @form && @field && @form.object.respond_to?(@field)

    @form.object.public_send(@field)
  end

  def amount(value)
    return nil if value.blank?

    number = value.is_a?(Numeric) ? BigDecimal(value.to_s) : BigDecimal(value.to_s.delete(@delimiter).tr(@separator, "."))
    number = number.abs unless @negative
    # round(0) gives an Integer; keep a BigDecimal.
    BigDecimal(number.round(@precision).to_s)
  rescue ArgumentError
    nil
  end

  # 1234567 -> 1,234,567, or the Indian way, 12,34,567: the last three
  # digits, then twos.
  def group(digits)
    return digits.gsub(/\B(?=(\d{3})+(?!\d))/, @delimiter) unless @grouping == :indian
    return digits if digits.length <= 3

    "#{digits[0...-3].gsub(/\B(?=(\d{2})+(?!\d))/, @delimiter)}#{@delimiter}#{digits[-3..]}"
  end
end

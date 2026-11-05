# frozen_string_literal: true

class UI::NumberInputPreview < ViewComponent::Preview
  # @label Playground
  # @param size select { choices: [sm, default, lg] }
  # @param label text
  # @param hint text
  # @param value number
  # @param min number
  # @param max number
  # @param step number
  # @param disabled toggle
  # @param readonly toggle
  # @param error text
  def playground(size: :default, label: "Quantity", hint: "", value: 2, min: 1, max: 10, step: 1,
                 disabled: false, readonly: false, error: "")
    render(UI::NumberInput.new(size: size.to_sym, label: label.presence, hint: hint.presence, value: value, min: min,
                               max: max, step: step, disabled: disabled, readonly: readonly,
                               error: error.presence, name: "quantity", class: "w-40"))
  end

  # @label Sizes
  def sizes; render_with_template; end

  # @label Cart Rows
  def cart; render_with_template; end

  # @label Decimal Steps
  def decimals; render_with_template; end

  # @label Stock Adjustment, Below Zero Allowed
  def stock_adjustment; render_with_template; end

  # @label States
  def states; render_with_template; end
end

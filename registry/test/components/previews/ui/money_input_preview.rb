# frozen_string_literal: true

class UI::MoneyInputPreview < ViewComponent::Preview
  # @label Playground
  # @param unit text
  # @param value text
  # @param precision number "Decimals: 2 for paise or cents, 0 for whole amounts"
  # @param grouping select { choices: ["", thousands, indian] } "Blank: Indian for ₹, thousands otherwise"
  # @param negative toggle
  # @param size select { choices: [sm, default, lg] }
  # @param label text
  # @param hint text
  # @param disabled toggle
  # @param error text
  def playground(unit: "₹", value: "123456.5", precision: 2, grouping: "", negative: false, size: :default,
                 label: "Amount", hint: "", disabled: false, error: "")
    render(UI::MoneyInput.new(name: "amount", unit: unit, value: value.presence, precision: precision,
                              grouping: grouping.presence, negative: negative, size: size.to_sym,
                              label: label.presence, hint: hint.presence, disabled: disabled,
                              error: error.presence, class: "max-w-xs"))
  end

  # @label Currencies
  def currencies; render_with_template; end

  # @label Sizes and States
  def sizes_and_states; render_with_template; end

  # @label Invoice Total, Following Live
  def invoice; render_with_template; end

  # @label Cash and Change at a Till
  def cash_tendered; render_with_template; end
end

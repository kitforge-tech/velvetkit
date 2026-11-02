# frozen_string_literal: true

class UI::ToggleGroupPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, outline] }
  # @param size select { choices: [sm, default, lg] }
  # @param multiple toggle
  # @param disabled toggle
  def playground(variant: :default, size: :default, multiple: false, disabled: false)
    render(UI::ToggleGroup.new(name: "period", value: "month", label: "Period", variant: variant.to_sym,
                               size: size.to_sym, multiple: multiple, disabled: disabled)) do |group|
      group.with_item(value: "day", label: "Day")
      group.with_item(value: "week", label: "Week")
      group.with_item(value: "month", label: "Month")
      group.with_item(value: "year", label: "Year")
    end
  end

  # @label Outline
  def outline; render_with_template; end

  # @label With Icons
  def with_icons; render_with_template; end

  # @label Icon Only
  def icon_only; render_with_template; end

  # @label Multiple
  def multiple; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label In a Form
  def in_form; render_with_template; end
end

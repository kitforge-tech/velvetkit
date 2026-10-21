# frozen_string_literal: true

class UI::RadioGroupPreview < ViewComponent::Preview
  # @label Playground
  # @param name    text
  # @param value   select { choices: ["", free, pro, enterprise] }
  # @param required toggle
  # @param disabled toggle
  def playground(name: "plan", value: "free", required: false, disabled: false)
    render(UI::RadioGroup.new(name: name, value: value.presence, required: required, disabled: disabled)) do |rg|
      rg.with_item(value: "free", label: "Free plan")
      rg.with_item(value: "pro", label: "Pro plan — $9/mo")
      rg.with_item(value: "enterprise", label: "Enterprise — Contact us")
    end
  end

  # @label Default
  def default; render_with_template; end

  # @label With Required
  def with_required; render_with_template; end

  # @label Disabled
  def disabled; render_with_template; end
end

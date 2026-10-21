# frozen_string_literal: true

class UI::SwitchPreview < ViewComponent::Preview
  # @label Playground
  # @param label    text
  # @param size     select { choices: [sm, default, lg] }
  # @param checked  toggle
  # @param required toggle
  # @param disabled toggle
  def playground(label: "Airplane mode", size: :default,
                 checked: false, required: false, disabled: false)
    render(UI::Switch.new(
      name: "demo", label: label, size: size.to_sym,
      checked: checked, required: required, disabled: disabled
    ))
  end

  # @label Default
  def default; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label States
  def states; render_with_template; end
end

# frozen_string_literal: true

class UI::CheckboxPreview < ViewComponent::Preview
  # @label Playground
  # @param label    text
  # @param size     select { choices: [sm, default, lg] }
  # @param checked  toggle
  # @param required toggle
  # @param error    toggle
  # @param disabled toggle
  def playground(label: "Accept terms", size: :default,
                 checked: false, required: false, error: false, disabled: false)
    render(UI::Checkbox.new(
      name: "demo", label: label, size: size.to_sym,
      checked: checked, required: required, error: error, disabled: disabled
    ))
  end

  # @label States
  def states; render_with_template; end

  # @label With Label
  def with_label; render_with_template; end

  # @label In Form
  def in_form; render_with_template; end
end

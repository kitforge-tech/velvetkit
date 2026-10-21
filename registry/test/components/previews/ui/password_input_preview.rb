# frozen_string_literal: true

class UI::PasswordInputPreview < ViewComponent::Preview
  # @label Playground
  # @param placeholder text
  # @param required toggle
  # @param disabled toggle
  # @param error toggle
  def playground(placeholder: "Enter your password", required: false, disabled: false, error: false)
    render(UI::PasswordInput.new(
      name: "user[password]",
      placeholder: placeholder,
      required: required,
      disabled: disabled,
      error: error
    ))
  end

  # @label States
  def states; render_with_template; end
end

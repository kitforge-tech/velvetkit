# frozen_string_literal: true

class UI::FileFieldPreview < ViewComponent::Preview
  # @label Playground
  # @param label text
  # @param hint text
  # @param multiple toggle
  # @param disabled toggle
  def playground(label: "Avatar", hint: "PNG or JPG, up to 5MB", multiple: false, disabled: false)
    render(UI::FileField.new(label: label, hint: hint, multiple: multiple, disabled: disabled))
  end

  # @label With Error
  def with_error; render_with_template; end

  # @label Multiple Files
  def multiple_files; render_with_template; end
end

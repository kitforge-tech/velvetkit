# frozen_string_literal: true

class UI::FieldsetPreview < ViewComponent::Preview
  # @label Playground
  # @param legend text
  # @param hint text
  # @param error text
  # @param required toggle
  # @param disabled toggle
  def playground(legend: "Notifications", hint: "Where we tell you about replies and mentions.",
                 error: "", required: false, disabled: false)
    render_with_template(locals: { legend: legend, hint: hint.presence, error: error.presence,
                                   required: required, disabled: disabled })
  end

  # @label Radio and toggle groups
  def groups; render_with_template; end

  # @label A block of fields
  def block_of_fields; render_with_template; end

  # @label Errors from the model
  def model_errors; render_with_template; end
end

# frozen_string_literal: true

class UI::FormFieldPreview < ViewComponent::Preview
  # @label On the built-in controls
  def default; render_with_template; end

  # @label Errors from the model
  def model_errors; render_with_template; end

  # @label Your own control
  def custom_control; render_with_template; end
end

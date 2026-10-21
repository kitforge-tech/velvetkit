# frozen_string_literal: true

class UI::DatePickerPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template
  end

  # @label States
  def states
    render_with_template
  end
end

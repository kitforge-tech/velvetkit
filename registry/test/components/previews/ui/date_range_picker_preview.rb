# frozen_string_literal: true

class UI::DateRangePickerPreview < ViewComponent::Preview
  # @label Playground
  # @param presets toggle
  # @param hint toggle
  # @param disabled toggle
  def playground(presets: true, hint: true, disabled: false)
    render(UI::DateRangePicker.new(label: "Period", presets: presets, hint: hint, disabled: disabled,
                                   from: Date.current.beginning_of_month, to: Date.current, class: "max-w-sm"))
  end

  # @label Report Filter
  def report_filter; render_with_template; end

  # @label Your Own Presets
  def custom_presets; render_with_template; end

  # @label States
  def states; render_with_template; end
end

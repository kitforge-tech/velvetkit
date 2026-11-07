# frozen_string_literal: true

class UI::DatePickerPreview < ViewComponent::Preview
  # @label Playground
  # @param range toggle
  # @param presets toggle
  # @param hint toggle
  # @param required toggle
  # @param disabled toggle
  def playground(range: false, presets: true, hint: true, required: false, disabled: false)
    if range
      render(UI::DatePicker.new(range: true, label: "Period", presets: presets, hint: hint, required: required, disabled: disabled,
                                from: Date.current.beginning_of_month, to: Date.current, class: "max-w-sm"))
    else
      render(UI::DatePicker.new(name: "date", label: "Date", hint: hint, required: required, disabled: disabled, class: "max-w-xs"))
    end
  end

  # @label A Date
  def default; render_with_template; end

  # @label A Range, for Report Filters
  def range; render_with_template; end

  # @label Your Own Presets
  def custom_presets; render_with_template; end

  # @label In a Form
  def in_form; render_with_template; end

  # @label States
  def states; render_with_template; end
end

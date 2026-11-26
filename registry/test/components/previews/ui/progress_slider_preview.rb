# frozen_string_literal: true

class UI::ProgressSliderPreview < ViewComponent::Preview
  # @label Playground
  # @param value number
  # @param min number
  # @param max number
  # @param step number
  # @param label text
  # @param value_text text "Can use %{value}"
  # @param show_value toggle "The caption under the bar"
  # @param bubble toggle
  # @param fill select { choices: [fade, brand] }
  # @param size select { choices: [sm, default, lg] }
  # @param disabled toggle
  # @param hint text
  # @param error text
  def playground(value: 60, min: 0, max: 100, step: 1, label: "Brightness", value_text: "%{value}%",
                 show_value: true, bubble: true, fill: :fade, size: :default, disabled: false, hint: "", error: "")
    render(UI::ProgressSlider.new(name: "brightness", value: value, min: min, max: max, step: step,
                                  label: label.presence, value_text: value_text.presence, show_value: show_value,
                                  bubble: bubble, fill: fill.to_sym, size: size.to_sym, disabled: disabled, hint: hint.presence,
                                  error: error.presence, class: "max-w-sm pt-10"))
  end

  # @label Fade and Brand Fills
  def fills; render_with_template; end

  # @label Named Steps
  def named_steps; render_with_template; end

  # @label Sizes and States
  def sizes_and_states; render_with_template; end

  # @label Playback Position
  def playback; render_with_template; end
end

# frozen_string_literal: true

class UI::SliderPreview < ViewComponent::Preview
  # @label Playground
  # @param range toggle "Two handles, a low and a high"
  # @param value number
  # @param min number
  # @param max number
  # @param step number
  # @param label text
  # @param show_value toggle
  # @param value_text text "Can use %{value}"
  # @param size select { choices: [sm, default, lg] }
  # @param disabled toggle
  # @param hint text
  # @param error text
  def playground(range: false, value: 40, min: 0, max: 100, step: 1, label: "Volume", show_value: true,
                 value_text: "%{value}%", size: :default, disabled: false, hint: "", error: "")
    render(UI::Slider.new(name: "volume", range: range, value: value, from: value, to: max, min: min, max: max,
                          step: step, label: label.presence, show_value: show_value, value_text: value_text.presence,
                          size: size.to_sym, disabled: disabled, hint: hint.presence, error: error.presence,
                          class: "max-w-sm"))
  end

  # @label Sizes and States
  def sizes_and_states; render_with_template; end

  # @label Volume, with Icons
  def volume; render_with_template; end

  # @label Price Range Filter
  def price_range; render_with_template; end

  # @label Opening Hours, with Marks
  def opening_hours; render_with_template; end

  # @label Named Steps
  def named_steps; render_with_template; end

  # @label Text Size, Following Live
  def text_size; render_with_template; end

  # @label Tip on a Card Reader
  def tip; render_with_template; end
end

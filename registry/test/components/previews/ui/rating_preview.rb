# frozen_string_literal: true

class UI::RatingPreview < ViewComponent::Preview
  # @label Playground
  # @param field toggle
  # @param value number
  # @param max number
  # @param size select { choices: [sm, default, lg] }
  # @param show_value toggle
  # @param count number
  # @param disabled toggle
  def playground(field: false, value: 3.5, max: 5, size: :default, show_value: true, count: 128, disabled: false)
    render_with_template(locals: { field: field, value: value, max: max.to_i.clamp(1, 10), size: size.to_sym,
                                   show_value: show_value, count: count.presence, disabled: disabled })
  end

  # @label Scores
  def scores; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label In a Form
  def in_form; render_with_template; end

  # @label Errors from the Model
  def model_errors; render_with_template; end
end

# frozen_string_literal: true

class UI::LabelPreview < ViewComponent::Preview
  # @label Playground
  # @param size    select { choices: [xs, sm, default, lg] }
  # @param weight  select { choices: [normal, medium, semibold] }
  # @param required toggle
  # @param disabled toggle
  def playground(size: :default, weight: :medium, required: false, disabled: false)
    render(UI::Label.new(size: size.to_sym, weight: weight.to_sym,
                         required: required, disabled: disabled)) { "Email address" }
  end

  # @label All Sizes
  def sizes; render_with_template; end

  # @label All Weights
  def weights; render_with_template; end

  # @label States
  def states; render_with_template; end
end

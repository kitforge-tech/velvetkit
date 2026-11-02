# frozen_string_literal: true

class UI::StepperPreview < ViewComponent::Preview
  # @label Playground
  # @param current number { min: 1, max: 4 }
  # @param orientation select { choices: [horizontal, vertical] }
  def playground(current: 2, orientation: :horizontal)
    render(UI::Stepper.new(current: current.to_i, orientation: orientation.to_sym)) do |stepper|
      stepper.with_step(title: "Account", description: "Name and email")
      stepper.with_step(title: "Plan", description: "Choose a plan")
      stepper.with_step(title: "Payment", description: "Card details")
    end
  end

  # @label Default
  def default; render_with_template; end

  # @label With Links Back
  def with_links; render_with_template; end

  # @label Vertical
  def vertical; render_with_template; end

  # @label With an Error
  def with_error; render_with_template; end

  # @label All Done
  def complete; render_with_template; end
end

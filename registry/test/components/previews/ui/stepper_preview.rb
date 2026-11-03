# frozen_string_literal: true

# The wizards below post to /demo/ paths; the docs site stops those requests
# and shows a toast instead. The live demo further up the page checks each
# step on the server.
class UI::StepperPreview < ViewComponent::Preview
  # @label Playground
  # @param current number { min: 1, max: 5 }
  # @param orientation select { choices: [horizontal, vertical] }
  # @param variant select { choices: [default, dot] }
  # @param align select { choices: [start, center] }
  # @param connector toggle
  # @param descriptions toggle
  def playground(current: 2, orientation: :horizontal, variant: :default, align: :start, connector: true,
                 descriptions: true)
    render(UI::Stepper.new(current: current.to_i, orientation: orientation.to_sym, variant: variant.to_sym,
                           align: align.to_sym, connector: connector)) do |stepper|
      [ [ "Account", "Name and email" ], [ "Plan", "Pick what fits" ], [ "Payment", "Card details" ],
        [ "Review", "Check and confirm" ] ].each do |title, description|
        stepper.with_step(title: title, description: (description if descriptions))
      end
    end
  end

  # @label Horizontal
  def price_calculator; render_with_template; end

  # @label Centered, with Descriptions
  def order_tracking; render_with_template; end

  # @label Dots
  def onboarding; render_with_template; end

  # @label Vertical
  def approvals; render_with_template; end

  # @label With an Error
  def failed_deploy; render_with_template; end

  # @label Without Lines
  def checklist; render_with_template; end

  # @label Wizard, Checked in the Browser
  def wizard; render_with_template; end

  # @label Beside the Form
  def sidebar; render_with_template; end

  # @label Steps Inline
  def inline; render_with_template; end

  # @label Dots in a Card
  def dot_wizard; render_with_template; end

  # @label Server-Driven, with Links Back
  def server_driven; render_with_template; end
end

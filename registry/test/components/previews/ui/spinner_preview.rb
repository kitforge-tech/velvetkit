# frozen_string_literal: true

class UI::SpinnerPreview < ViewComponent::Preview
  # @label Playground
  # @param size select { choices: [xs, sm, default, lg, xl] }
  def playground(size: :default)
    render(UI::Spinner.new(size: size.to_sym))
  end

  # @label All Sizes
  def sizes
    render_with_template
  end

  # @label In Buttons
  def in_buttons
    render_with_template
  end
end

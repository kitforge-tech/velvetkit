# frozen_string_literal: true

class UI::SkeletonPreview < ViewComponent::Preview
  # @label Playground
  # @param shape select { choices: [text, circle, rectangle] }
  def playground(shape: :text)
    render(UI::Skeleton.new(shape: shape.to_sym, class: shape.to_sym == :circle ? nil : "w-64"))
  end

  # @label Shapes
  def shapes; render_with_template; end

  # @label Card Placeholder
  def card_placeholder; render_with_template; end
end

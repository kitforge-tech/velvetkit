# frozen_string_literal: true

class UI::SheetPreview < ViewComponent::Preview
  # @label Playground
  # @param side select { choices: [right, left, top, bottom] }
  def playground(side: :right)
    @side = side.to_sym
    render_with_template
  end

  # @label Right
  def right; render_with_template; end

  # @label Left
  def left; render_with_template; end

  # @label Top
  def top; render_with_template; end

  # @label Bottom
  def bottom; render_with_template; end
end

# frozen_string_literal: true

class UI::ButtonToPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, destructive, outline, secondary, ghost, link] }
  # @param size select { choices: [sm, default, lg] }
  # @param full_width toggle
  # @param text text
  def playground(variant: :default, size: :default, full_width: false, text: "Submit")
    render(UI::ButtonTo.new("#", variant: variant.to_sym, size: size.to_sym, full_width: full_width)) { text }
  end

  # @label Variants
  def variants; render_with_template; end

  # @label With Icon
  def with_icon; render_with_template; end

  # @label States
  def states; render_with_template; end
end

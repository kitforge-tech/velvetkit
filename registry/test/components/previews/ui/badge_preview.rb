# frozen_string_literal: true

class UI::BadgePreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, secondary, destructive, outline, success, warning] }
  # @param size    select { choices: [sm, default, lg] }
  # @param text    text
  def playground(variant: :default, size: :default, text: "Badge")
    render(UI::Badge.new(variant: variant.to_sym, size: size.to_sym)) { text }
  end

  # @label All Variants
  def variants; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label With Icon
  def with_icon; render_with_template; end
end

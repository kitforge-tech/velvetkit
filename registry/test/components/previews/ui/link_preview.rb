# frozen_string_literal: true

class UI::LinkPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [link, default, destructive, outline, secondary, ghost] }
  # @param size select { choices: [sm, default, lg] }
  # @param button_variant select { choices: [true, false] }
  def playground(variant: :link, size: :default, button_variant: false)
    render(UI::Link.new(href: "#", variant: variant.to_sym, size: size.to_sym, button_variant: button_variant == "true")) { "Click here" }
  end

  # @label Variants
  def variants; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label With Icons
  def with_icons; render_with_template; end
end

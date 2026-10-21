# frozen_string_literal: true

class UI::AvatarPreview < ViewComponent::Preview
  # @label Playground
  # @param size  select { choices: [sm, default, lg, xl] }
  # @param shape select { choices: [circle, rounded] }
  # @param color select { choices: [default, primary, destructive, amber, emerald, purple, sky] }
  # @param initials text
  def playground(size: :default, shape: :circle, color: :default, initials: "JD")
    render(UI::Avatar.new(size: size.to_sym, shape: shape.to_sym, color: color.to_sym)) { initials }
  end

  # @label Sizes
  def sizes; render_with_template; end

  # @label Shapes
  def shapes; render_with_template; end

  # @label Colors
  def colors; render_with_template; end

  # @label With Image
  def with_image; render_with_template; end
end

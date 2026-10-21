# frozen_string_literal: true

class UI::ImagePreview < ViewComponent::Preview
  # @label Playground
  # @param rounded select { choices: [none, xs, sm, md, lg, xl, full] }
  # @param width text
  def playground(rounded: :sm, width: "160px")
    render(UI::Image.new(src: "/icon.png", rounded: rounded.to_sym, width: width))
  end

  # @label Radii
  def radii; render_with_template; end

  # @label Sizing
  def sizing; render_with_template; end
end

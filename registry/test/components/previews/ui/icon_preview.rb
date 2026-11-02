# frozen_string_literal: true

class UI::IconPreview < ViewComponent::Preview
  # @label Playground
  # @param icon text "An SVG in app/assets/icons, without .svg"
  # @param size select { choices: [xs, sm, default, lg, xl] }
  def playground(icon: "menu", size: :default)
    render(UI::Icon.new(name: icon, size: size.to_sym))
  end

  # @label All Sizes
  def sizes
    render_with_template
  end

  # @label Common Icons
  def common
    render_with_template
  end
end

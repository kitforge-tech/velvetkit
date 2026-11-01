# frozen_string_literal: true

class UI::IconPreview < ViewComponent::Preview
  # @label Playground
  # @param name text "Lucide icon name (must be registered in app/javascript/lucide-icon.ts)"
  # @param size select { choices: [xs, sm, default, lg, xl] }
  def playground(name: "menu", size: :default)
    render(UI::Icon.new(name: name, size: size.to_sym))
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

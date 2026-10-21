# frozen_string_literal: true

class UI::ThemeTogglePreview < ViewComponent::Preview
  # @label Playground
  # @param label text
  def playground(label: "Change theme")
    render(UI::ThemeToggle.new(label: label))
  end

  # @label In A Header
  def in_a_header; render_with_template; end

  # @label Palette
  def palette; render_with_template; end
end

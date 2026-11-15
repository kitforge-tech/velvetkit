# frozen_string_literal: true

class UI::SelectionBarPreview < ViewComponent::Preview
  # @label Over a Table
  def table; render_with_template; end

  # @label Floating, Over a Grid of Photos
  def floating; render_with_template; end
end

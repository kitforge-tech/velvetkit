# frozen_string_literal: true

class UI::TableOfContentsPreview < ViewComponent::Preview
  # @label Nested sections
  def default; render_with_template; end

  # @label Flat
  def flat; render_with_template; end
end

# frozen_string_literal: true

class UI::TypographyPreview < ViewComponent::Preview
  # @label Headings
  def headings
    render_with_template
  end

  # @label Text styles
  def text_styles
    render_with_template
  end

  # @label Code and quotes
  def code_and_quotes
    render_with_template
  end

  # @label An article
  def article
    render_with_template
  end
end

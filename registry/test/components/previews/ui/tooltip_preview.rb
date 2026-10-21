# frozen_string_literal: true

class UI::TooltipPreview < ViewComponent::Preview
  # @label Playground
  # @param side select { choices: [top, right, bottom, left] }
  # @param align select { choices: [start, center, end] }
  def playground(side: :top, align: :center)
    render(UI::Tooltip.new) do |tooltip|
      tooltip.with_trigger do
        tag.button("Hover me", class: "px-4 py-2 bg-primary text-primary-foreground rounded-md")
      end
      tooltip.with_content(side: side.to_sym, align: align.to_sym) do
        "This is a tooltip"
      end
    end
  end

  # @label Default
  def default; render_with_template; end

  # @label Positions
  def positions; render_with_template; end

  # @label With Button
  def with_button; render_with_template; end

  # @label With Icon
  def with_icon; render_with_template; end
end

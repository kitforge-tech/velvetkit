# frozen_string_literal: true

class UI::PopoverPreview < ViewComponent::Preview
  # @label Playground
  # @param side select { choices: [top, right, bottom, left] }
  # @param align select { choices: [start, center, end] }
  # @param show_close toggle
  def playground(side: :top, align: :center, show_close: false)
    render(UI::Popover.new) do |popover|
      popover.with_trigger { "Open Popover" }
      popover.with_content(side: side.to_sym, align: align.to_sym, show_close: show_close) do |content|
        content.with_title { "Popover Title" }
        "This is the popover content with rich text support."
      end
    end
  end

  # @label Default
  def default; render_with_template; end

  # @label Positions
  def positions; render_with_template; end

  # @label With Close Button
  def with_close_button; render_with_template; end

  # @label With Rich Content
  def with_rich_content; render_with_template; end

  # @label Without Title
  def without_title; render_with_template; end
end

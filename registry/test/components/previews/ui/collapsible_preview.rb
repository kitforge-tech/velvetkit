# frozen_string_literal: true

class UI::CollapsiblePreview < ViewComponent::Preview
  # @label Playground
  # @param open toggle
  # @param size select { choices: [sm, default, lg] }
  def playground(open: false, size: :default)
    render(UI::Collapsible.new(open: open, size: size.to_sym, class: "max-w-xs")) do |c|
      c.with_trigger { "Advanced settings" }
      "Hidden until opened."
    end
  end

  # @label Navigation tree
  def default; render_with_template; end

  # @label Show more
  def show_more; render_with_template; end
end

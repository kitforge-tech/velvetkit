# frozen_string_literal: true

class UI::MenuPreview < ViewComponent::Preview
  # @label Playground
  # @param side select { choices: [top, right, bottom, left] }
  # @param align select { choices: [start, center, end] }
  def playground(side: :bottom, align: :start)
    render(UI::Menu.new) do |menu|
      menu.with_trigger(variant: :outline) { "Open Menu" }
      menu.with_content(side: side.to_sym, align: align.to_sym) do |content|
        content.with_label("My Account")
        content.with_item("Profile")
        content.with_item("Billing")
        content.with_item("Settings")
        content.with_divider
        content.with_item("Log out", variant: :destructive)
      end
    end
  end

  # @label Variants
  def variants; render_with_template; end

  # @label Positions
  def positions; render_with_template; end
end

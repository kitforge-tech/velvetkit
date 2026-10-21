# frozen_string_literal: true

class UI::CardPreview < ViewComponent::Preview
  # @label Playground
  # @param title text
  # @param description text
  # @param show_footer toggle
  def playground(title: "Create project", description: "Deploy your new project in one click.", show_footer: true)
    render(UI::Card.new) do |card|
      card.with_header do |header|
        header.with_title { title }
        header.with_description { description }
      end
      card.with_content do
        tag.p(class: "text-sm text-muted-foreground") { "Card body content goes here." }
      end
      if show_footer
        card.with_footer do
          tag.div(class: "flex gap-2") do
            safe_join([
              render(UI::Button.new(variant: :primary, size: :sm)) { "Deploy" },
              render(UI::Button.new(variant: :outline, size: :sm)) { "Cancel" }
            ])
          end
        end
      end
    end
  end

  # @label Default (content only)
  def default; render_with_template; end

  # @label With Header
  def with_header; render_with_template; end

  # @label With Footer
  def with_footer; render_with_template; end

  # @label Complete (all sections)
  def complete; render_with_template; end

  # @label Settings Form
  def settings_form; render_with_template; end
end

# frozen_string_literal: true

class UI::BannerPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [introduction, promotion] }
  # @param dismissible toggle
  def playground(variant: :introduction, dismissible: true)
    render(UI::Banner.new(variant: variant.to_sym, dismissible: dismissible)) do |banner|
      banner.with_title { "Try our new pipeline editor" }
      "Visualize and edit your CI/CD pipelines with an interactive drag-and-drop editor. No YAML required."
      banner.with_action do
        "<a href='#' class='inline-flex items-center text-sm font-medium text-primary hover:underline'>Learn more</a>".html_safe
      end
    end
  end

  # @label Introduction
  def introduction; render_with_template; end

  # @label Promotion
  def promotion; render_with_template; end

  # @label With Illustration
  def with_illustration; render_with_template; end
end

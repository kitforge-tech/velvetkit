# frozen_string_literal: true

class UI::EmptyStatePreview < ViewComponent::Preview
  # @label Playground
  # @param title text
  # @param description text
  # @param variant select { choices: [default, outline] }
  def playground(title: "No messages", description: "When someone writes to you, it will show up here.", variant: :default)
    render(UI::EmptyState.new(icon: "inbox", title: title, description: description, variant: variant.to_sym))
  end

  # @label With Actions
  def with_actions; render_with_template; end

  # @label Outline
  def outline; render_with_template; end

  # @label No Search Results
  def no_results; render_with_template; end

  # @label With an Avatar
  def with_media; render_with_template; end

  # @label In a Card
  def in_card; render_with_template; end
end

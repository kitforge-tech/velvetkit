# frozen_string_literal: true

class UI::AlertPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, destructive, warning, success, info] }
  # @param title   text
  # @param description text
  def playground(variant: :default, title: "Heads up!", description: "This is a sample alert message.")
    render(UI::Alert.new(variant: variant.to_sym)) do |alert|
      alert.with_title { title }
      alert.with_description { description }
    end
  end

  # @label All Variants
  def variants; render_with_template; end

  # @label With Icon
  def with_icon; render_with_template; end

  # @label Title Only
  def title_only; render_with_template; end

  # @label With Link
  def with_link; render_with_template; end

  # @label Dismissible
  def dismissible
    render(UI::Alert.new(variant: :info, dismissible: true)) do |alert|
      alert.with_title { "Update available" }
      alert.with_description { "A new version of the application is ready to install." }
    end
  end
end

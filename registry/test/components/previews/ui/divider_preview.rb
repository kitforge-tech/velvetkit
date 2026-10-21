# frozen_string_literal: true

class UI::DividerPreview < ViewComponent::Preview
  # @label Playground
  # @param orientation select { choices: [horizontal, vertical] }
  # @param label text
  def playground(orientation: :horizontal, label: nil)
    render(UI::Divider.new(orientation: orientation.to_sym, label: label.presence))
  end

  # @label Horizontal
  def horizontal; render_with_template; end

  # @label Vertical
  def vertical; render_with_template; end

  # @label With Label
  def with_label; render_with_template; end
end

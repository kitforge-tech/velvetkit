# frozen_string_literal: true

class UI::TextPreview < ViewComponent::Preview
  # @label Playground
  # @param as select { choices: [p, span, div] }
  # @param size select { choices: [xs, sm, base, lg, xl, 2xl, 3xl, 4xl] }
  # @param weight select { choices: [normal, medium, semibold, bold] }
  # @param tone select { choices: [default, muted, destructive] }
  def playground(as: :p, size: :base, weight: :normal, tone: :default)
    render(UI::Text.new(
      as: as.to_sym,
      size: size.to_sym,
      weight: weight.to_sym,
      tone: tone.to_sym
    )) { "The quick brown fox jumps over the lazy dog." }
  end

  # @label Sizes
  def sizes; render_with_template; end

  # @label Weights
  def weights; render_with_template; end

  # @label Tones
  def tones; render_with_template; end
end

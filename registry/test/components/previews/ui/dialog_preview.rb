# frozen_string_literal: true

class UI::DialogPreview < ViewComponent::Preview
  # @label Playground
  # @param trigger_variant select { choices: [default, outline, secondary, ghost] }
  # @param size select { choices: [sm, default, lg, xl] }
  # @param show_close toggle
  def playground(trigger_variant: :outline, size: :default, show_close: true)
    @trigger_variant = trigger_variant.to_sym
    @size = size.to_sym
    @show_close = show_close
    render_with_template
  end

  # @label Default
  def default; render_with_template; end

  # @label Confirmation
  def confirmation; render_with_template; end

  # @label Custom Trigger
  def custom_trigger; render_with_template; end

  # @label Long Content
  def long_content; render_with_template; end

  # @label Sizes
  def sizes; render_with_template; end

  # @label Without Close Button
  def without_close_button; render_with_template; end

  # @label Without Title
  def without_title; render_with_template; end

  # @label Scrollable Body
  def scrollable_body; render_with_template; end
end

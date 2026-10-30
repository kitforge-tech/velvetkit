# frozen_string_literal: true

class UI::ToastPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, success, destructive, warning, info] }
  # @param title text
  # @param description text
  # @param duration number Seconds before it auto-dismisses; 0 stays until dismissed.
  # @param dismissible toggle
  def playground(variant: :success, title: "Saved", description: "Your changes have been saved.",
                  duration: 5, dismissible: true)
    render(UI::Toast.new(variant: variant.to_sym, title: title, description: description,
                          duration: duration, dismissible: dismissible))
  end

  # @label All Variants
  def variants; render_with_template; end

  # @label With Action
  def with_action; render_with_template; end

  # @label Live Viewport
  #
  # Each button fires the same `toast:show` event the `toast()` helper
  # dispatches, so this is exactly what a client-triggered toast looks like:
  # stacking, auto-dismiss and pause-on-hover all come from the real
  # UI::Toast::Viewport and ui--toast controllers, not a preview-only stand-in.
  def live_viewport; render_with_template; end
end

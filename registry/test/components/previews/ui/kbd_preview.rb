# frozen_string_literal: true

class UI::KbdPreview < ViewComponent::Preview
  # @label Playground
  # @param keys text "Keys joined by +, like mod+shift+k"
  # @param then_keys text "A second step, for a sequence like G then I"
  # @param size select { choices: [sm, default, lg] }
  def playground(keys: "mod+k", then_keys: "", size: :default)
    render(UI::Kbd.new([ keys, then_keys.presence ].compact, size: size.to_sym))
  end

  # @label Keys and Shortcuts
  def keys; render_with_template; end

  # @label In a Search Field
  def search_field; render_with_template; end

  # @label In a Menu
  def menu; render_with_template; end

  # @label In a Tooltip and on Buttons
  def tooltip_and_buttons; render_with_template; end

  # @label Shortcuts That Work
  def bound; render_with_template; end

  # @label Shortcuts List
  def shortcuts_list; render_with_template; end

  # @label Billing Keys at a Till
  def till; render_with_template; end
end

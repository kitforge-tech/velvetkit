# frozen_string_literal: true

class UI::TabsPreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [line, pill, solid] }
  # @param size    select { choices: [sm, default, lg] }
  def playground(variant: :line, size: :default)
    render(UI::Tabs.new(variant: variant.to_sym, size: size.to_sym, default_value: "account")) do |tabs|
      tabs.with_list do |list|
        list.with_trigger(value: "account")  { "Account" }
        list.with_trigger(value: "password") { "Password" }
        list.with_trigger(value: "team")     { "Team" }
        list.with_trigger(value: "billing", disabled: true) { "Billing" }
      end
      tabs.with_panel(value: "account")  { "Account settings live here." }
      tabs.with_panel(value: "password") { "Password rotation lives here." }
      tabs.with_panel(value: "team")     { "Team membership lives here." }
      tabs.with_panel(value: "billing")  { "Billing details live here." }
    end
  end

  # @label Default (Line)
  def default; render_with_template; end

  # @label Pill Variant
  def pill_variant; render_with_template; end

  # @label With Icons
  def with_icons; render_with_template; end

  # @label Settings Form
  def settings_form; render_with_template; end
end

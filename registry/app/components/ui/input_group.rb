# frozen_string_literal: true

# UI::InputGroup — wrapper that visually merges a UI::Input with one or more
# Addon decorators (icons, text, icon-buttons). The wrapper owns the border and
# focus ring; the inner Field strips its own so there's no double border.
#
# The wrapper's focus ring inherits from UI::Base::FOCUS_RING (same as Button)
# wrapped in has-[] selectors, so changes propagate automatically.
#
# Usage:
#   <%= render(UI::InputGroup.new) do |g| %>
#     <%= g.with_addon(align: "inline-start") { |a| a.with_icon(name: "mail") } %>
#     <%= g.with_field(type: :email, placeholder: "you@example.com") %>
#   <% end %>
class UI::InputGroup < UI::Base
  # Wrapper owns the control's focus ring, lit when the control itself has
  # focus (mouse or keyboard). Not :focus-within: an addon button has its own
  # ring, and the two would stack.
  # An invalid, enabled control turns the border red: [aria-invalid]:enabled,
  # because a :has() nested inside has-[] is invalid CSS and drops the rule.
  WRAPPER_BASE =
    "group/input-group relative flex w-full items-center rounded-md border " \
    "border-input bg-background " \
    "transition-all " \
    "h-9 min-w-0 has-[>textarea]:h-auto " \
    "has-[>[data-align=inline-start]]:[&>input]:pl-2 " \
    "has-[>[data-align=inline-end]]:[&>input]:pr-2 " \
    "has-[>[data-align=block-start]]:h-auto " \
    "has-[>[data-align=block-start]]:flex-col " \
    "has-[>[data-align=block-start]]:[&>input]:pb-3 " \
    "has-[>[data-align=block-end]]:h-auto " \
    "has-[>[data-align=block-end]]:flex-col " \
    "has-[>[data-align=block-end]]:[&>input]:pt-3 " \
    "has-[[data-slot]:focus]:ring-2 " \
    "has-[[data-slot]:focus]:ring-primary " \
    "has-[[data-slot]:focus]:ring-offset-1 " \
    "ring-offset-background " \
    "has-[[data-slot][aria-invalid=true]:enabled]:border-destructive " \
    "has-[[data-slot][aria-invalid=true]:enabled]:ring-destructive " \
    "has-[input:disabled]:border-input " \
    "has-[input:disabled]:bg-muted " \
    "has-[input:disabled]:opacity-50"

  renders_many :addons, UI::InputGroup::Addon

  renders_one :field, UI::InputGroup::Field

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  # The invalid state comes from the field's aria-invalid, via WRAPPER_BASE.
  def wrapper_classes
    cn(WRAPPER_BASE, @user_class)
  end
end

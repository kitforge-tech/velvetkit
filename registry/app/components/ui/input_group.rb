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
  # Wrapper owns the focus ring via :focus-within so it lights up on any
  # descendant focus (mouse click or keyboard). focus-visible is too narrow.
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
    "focus-within:ring-2 " \
    "focus-within:ring-primary " \
    "focus-within:ring-offset-1 " \
    "ring-offset-background " \
    "has-[[data-slot][aria-invalid=true]:not(:has(input:disabled))]:border-destructive " \
    "has-[[data-slot][aria-invalid=true]:not(:has(input:disabled))]:ring-destructive " \
    "has-[input:disabled]:border-input " \
    "has-[input:disabled]:bg-muted " \
    "has-[input:disabled]:opacity-50"

  renders_many :addons, UI::InputGroup::Addon

  renders_one :field, UI::InputGroup::Field

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def wrapper_classes
    # Propagate error styling to the wrapper when the field is in error state.
    error = field&.instance_variable_get(:@error)
    cn(WRAPPER_BASE, { "border-destructive" => error }, @user_class)
  end
end

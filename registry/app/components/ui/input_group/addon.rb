# frozen_string_literal: true

# UI::InputGroup::Addon — positional decorator slot inside an InputGroup.
#
# align variants mirror UI::InputGroupItem:
#   inline-start  — left prefix (icon, text, button)
#   inline-end    — right suffix
#   block-start   — full-width top row (e.g. floating label)
#   block-end     — full-width bottom row (e.g. character count)
class UI::InputGroup::Addon < UI::Base
  ALIGN_CLASSES = {
    "inline-start" =>
      "order-first pl-3 has-[>button]:ml-[-0.45rem] has-[>kbd]:ml-[-0.35rem]",
    "inline-end" =>
      "order-last pr-3 has-[>button]:mr-[-0.45rem] has-[>kbd]:mr-[-0.35rem]",
    "block-start" =>
      "order-first w-full justify-start px-3 pt-3 group-has-[>input]/input-group:pt-2.5",
    "block-end" =>
      "order-last w-full justify-start px-3 pb-3 group-has-[>input]/input-group:pb-2.5"
  }.freeze

  BASE_CLASSES =
    "text-muted-foreground flex h-auto cursor-text items-center justify-center " \
    "gap-2 py-1.5 text-sm font-medium select-none " \
    "[&>svg:not([class*='size-'])]:size-4 " \
    "group-data-[disabled=true]/input-group:opacity-50"

  renders_one :icon, ->(name:, **opts) { UI::Icon.new(name: name, **opts) }

  renders_one :icon_button, ->(**opts) {
    UI::Button.new(
      type: :button, variant: :ghost,
      class: cn(
        "text-sm flex gap-2 items-center h-6 gap-1 px-2",
        "rounded-[calc(var(--radius)-5px)]",
        "[&>svg:not([class*='size-'])]:size-3.5 has-[>svg]:px-2",
        # Inside a field a click shouldn't ring the button (it reads as a
        # second ring on the field); keyboard focus still does.
        "focus:ring-0 focus:ring-offset-0 focus-visible:ring-2 focus-visible:ring-offset-1"
      ),
      **opts
    )
  }

  def initialize(align: "inline-start", class: nil, **html_attrs)
    @align      = align.to_s
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(BASE_CLASSES, ALIGN_CLASSES[@align], @user_class)
  end
end

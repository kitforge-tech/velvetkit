# frozen_string_literal: true

# One choice in a UI::ToggleGroup: a label wrapping a visually hidden radio or
# checkbox. The block, or `label:`, is its text; `icon:` draws an icon before
# it, and `icon_only: true` hides the text from sight but keeps it for screen
# readers and as a tooltip.
class UI::ToggleGroup::Item < UI::Base
  HEIGHTS = {
    default: { sm: "h-7 px-2.5", default: "h-8 px-3", lg: "h-9 px-3.5" },
    outline: { sm: "h-8 px-2.5", default: "h-9 px-3", lg: "h-10 px-3.5" }
  }.freeze

  ICON_ONLY = {
    default: { sm: "h-7 w-7", default: "h-8 w-8", lg: "h-9 w-9" },
    outline: { sm: "h-8 w-8", default: "h-9 w-9", lg: "h-10 w-10" }
  }.freeze

  CHECKED = {
    default: "has-[:checked]:bg-background has-[:checked]:text-foreground has-[:checked]:shadow-sm",
    outline: "has-[:checked]:bg-accent has-[:checked]:text-accent-foreground"
  }.freeze

  def initialize(value:, label: nil, icon: nil, icon_only: false, disabled: false, class: nil, **html_attrs)
    @value      = value.to_s
    @label      = label
    @icon       = icon
    @icon_only  = icon_only
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_group_context(group)
    @group = group
  end

  def icon? = @icon.present?
  def icon_only? = @icon_only && icon?
  def text = content.presence || @label

  def classes
    variant = @group.variant.to_sym
    size = @group.size.to_sym
    cn(
      "relative inline-flex shrink-0 cursor-pointer select-none items-center justify-center gap-1.5 " \
      "whitespace-nowrap text-sm font-medium transition-colors " \
      "has-[:focus-visible]:z-10 has-[:focus-visible]:outline-none " \
      "has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-ring " \
      "has-[:disabled]:pointer-events-none has-[:disabled]:opacity-50",
      # The outline group clips its items to its rounded corners, so the ring
      # goes inside the item there.
      variant == :default ? "rounded-md hover:text-foreground" : "hover:bg-muted hover:text-foreground has-[:focus-visible]:ring-inset",
      (icon_only? ? ICON_ONLY : HEIGHTS).dig(variant, size),
      CHECKED[variant],
      @user_class
    )
  end

  def label_attrs
    attrs = @html_attrs.except(:data)
    attrs[:class] = classes
    attrs[:title] = text if icon_only? && text.present?
    attrs[:data] = { slot: "toggle-group-item" }.merge(@html_attrs[:data] || {})
    attrs
  end

  def input_attrs
    {
      type: @group.multiple? ? "checkbox" : "radio",
      name: @group.input_name,
      value: @value,
      checked: @group.selected.include?(@value),
      disabled: @disabled || @group.disabled?,
      required: @group.required?,
      class: "peer sr-only"
    }
  end

  def icon_size
    @group.size.to_sym == :lg ? :default : :sm
  end
end

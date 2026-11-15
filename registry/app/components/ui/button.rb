# frozen_string_literal: true

class UI::Button < UI::Base
  ICON_SIZE_FOR_BUTTON_SIZE = {
    sm:      :xs,
    default: :sm,
    lg:      :default,
    icon:    :sm,
    icon_sm: :xs
  }.freeze

  # The disabled-state utilities below carry Tailwind v4 `!` (important) so
  # they beat the legacy unlayered UI CSS — unlayered rules otherwise
  # outrank any layered Tailwind utility regardless of specificity.
  variants(
    base: "inline-flex items-center justify-center gap-2 whitespace-nowrap " \
          "rounded-md text-sm font-medium " \
          "#{UI::Base::FOCUS_RING} " \
          "disabled:pointer-events-none " \
          "disabled:bg-muted! disabled:text-muted-foreground!",
    variants: {
      variant: {
        default:     "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive",
        outline:     "border border-input bg-background hover:bg-accent hover:text-accent-foreground " \
                     "disabled:border-input!",
        secondary:   "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost:       "hover:bg-accent hover:text-accent-foreground disabled:bg-transparent!",
        link:        "text-primary underline-offset-4 hover:underline " \
                     "disabled:bg-transparent! disabled:no-underline!"
      },
      size: {
        default: "h-9 px-4 py-2",
        sm:      "h-8 rounded-md px-3 text-xs",
        lg:      "h-10 rounded-md px-8",
        icon:    "h-9 w-9",
        icon_sm: "h-7 w-7"
      }
    },
    defaults: { variant: :default, size: :default }
  )

  renders_one :leading_icon, ->(name:, size: nil, **opts) {
    UI::Icon.new(name: name, size: size || ICON_SIZE_FOR_BUTTON_SIZE.fetch(@size, :default), **opts)
  }

  renders_one :trailing_icon, ->(name:, size: nil, **opts) {
    UI::Icon.new(name: name, size: size || ICON_SIZE_FOR_BUTTON_SIZE.fetch(@size, :default), **opts)
  }

  def initialize(variant: :default, size: :default, type: :button,
                 full_width: false, loading: false, disabled: false,
                 as_child: false, class: nil, **html_attrs)
    @variant = variant
    @size = size
    @type = type
    @full_width = full_width
    @loading = loading
    @disabled = disabled
    @as_child = as_child
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def effective_disabled?
    @disabled || @loading
  end

  def classes
    cn(
      variant_classes(variant: @variant, size: @size),
      "disabled:cursor-not-allowed",
      { "w-full" => @full_width },
      @user_class
    )
  end

  def loader_icon
    UI::Spinner.new(size: ICON_SIZE_FOR_BUTTON_SIZE.fetch(@size, :default))
  end
end

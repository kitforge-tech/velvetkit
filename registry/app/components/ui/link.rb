# frozen_string_literal: true

class UI::Link < UI::Base
  ICON_SIZE_FOR_LINK_SIZE = {
    sm: :xs,
    default: :sm,
    lg: :default
  }.freeze

  variants(
    base: "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-sm text-sm font-medium " \
          "#{UI::Base::FOCUS_RING}",
    variants: {
      variant: {
        link:        "text-primary underline-offset-4 hover:underline",
        default:     "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-white hover:bg-destructive/90 focus:ring-destructive",
        outline:     "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary:   "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost:       "hover:bg-accent hover:text-accent-foreground"
      },
      size: {
        sm:      "h-8 rounded-sm px-3 text-xs",
        default: "h-9 px-4 py-2",
        lg:      "h-10 rounded-sm px-8"
      }
    },
    defaults: { variant: :link, size: :default }
  )

  renders_one :leading_icon, ->(name:, size: nil, **opts) {
    UI::Icon.new(name: name, size: size || ICON_SIZE_FOR_LINK_SIZE.fetch(@size, :default), **opts)
  }

  renders_one :trailing_icon, ->(name:, size: nil, **opts) {
    UI::Icon.new(name: name, size: size || ICON_SIZE_FOR_LINK_SIZE.fetch(@size, :default), **opts)
  }

  def initialize(href: "#", variant: :link, size: :default, button_variant: false, truncate: false, class: nil, **html_attrs)
    @href = href
    @variant = variant
    @size = size
    @button_variant = button_variant
    @truncate = truncate
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    base = if @button_variant
             variant_classes(variant: @variant, size: @size)
    else
             cn(self.class.variant_config[:base], self.class.variant_config[:variants][:variant][:link])
    end
    cn(base, { "max-w-32 truncate" => @truncate }, @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:href] = @href
    opts[:class] = classes
    opts
  end
end

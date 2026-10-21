# frozen_string_literal: true

class UI::Badge < UI::Base
  variants(
    base: "inline-flex items-center justify-center gap-1 rounded-full font-medium whitespace-nowrap border border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1",
    variants: {
      variant: {
        default:     "bg-primary text-primary-foreground hover:bg-primary/80",
        secondary:   "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        destructive: "bg-destructive text-white hover:bg-destructive/80",
        outline:     "text-foreground border-input",
        success:     "bg-emerald-500 dark:bg-emerald-600 text-white hover:bg-emerald-500/80 dark:hover:bg-emerald-600/80",
        warning:     "bg-amber-500 dark:bg-amber-600 text-white hover:bg-amber-500/80 dark:hover:bg-amber-600/80"
      },
      size: {
        sm:      "h-5 px-1.5 text-[10px] leading-none",
        default: "h-6 px-2 text-xs leading-none",
        lg:      "h-7 px-2.5 text-sm leading-none"
      }
    },
    defaults: { variant: :default, size: :default }
  )

  renders_one :leading_icon, ->(name:, size: nil, **opts) {
    UI::Icon.new(name: name, size: size || :xs, **opts)
  }

  def initialize(variant: :default, size: :default, class: nil, **html_attrs)
    @variant = variant
    @size = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(variant_classes(variant: @variant, size: @size), @user_class)
  end
end

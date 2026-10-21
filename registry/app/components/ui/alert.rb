# frozen_string_literal: true

class UI::Alert < UI::Base
  DEFAULT_ICONS = {
    default:     "info",
    destructive: "circle-alert",
    warning:     "circle-alert",
    success:     "circle-check",
    info:        "info"
  }.freeze

  variants(
    base: "relative w-full rounded-md border p-4 " \
          "flex items-start gap-3 " \
          "[&>i]:translate-y-0.5 [&>i]:shrink-0",
    variants: {
      variant: {
        default:     "bg-background text-foreground border-input",
        destructive: "bg-destructive/10 text-destructive border-destructive/30",
        warning:     "bg-amber-50 text-amber-800 border-amber-300 " \
                     "dark:bg-amber-950/30 dark:text-amber-200 dark:border-amber-800",
        success:     "bg-emerald-50 text-emerald-800 border-emerald-300 " \
                     "dark:bg-emerald-950/30 dark:text-emerald-200 dark:border-emerald-800",
        info:        "bg-sky-50 text-sky-800 border-sky-300 " \
                     "dark:bg-sky-950/30 dark:text-sky-200 dark:border-sky-800"
      }
    },
    defaults: { variant: :default }
  )

  renders_one :icon, ->(name:, **opts) {
    UI::Icon.new(name: name, size: opts.delete(:size) || :sm, class: cn("shrink-0", opts.delete(:class)), **opts)
  }
  renders_one :title, UI::Alert::Title
  renders_one :description, UI::Alert::Description

  def initialize(variant: :default, dismissible: false, class: nil, **html_attrs)
    @variant = variant
    @dismissible = dismissible
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def dismissible?
    @dismissible
  end

  def classes
    cn(variant_classes(variant: @variant), @user_class)
  end

  def default_icon_name
    DEFAULT_ICONS.fetch(@variant)
  end
end

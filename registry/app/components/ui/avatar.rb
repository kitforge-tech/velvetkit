# frozen_string_literal: true

class UI::Avatar < UI::Base
  variants(
    base: "relative flex shrink-0 overflow-hidden",
    variants: {
      shape: {
        circle:  "rounded-full",
        rounded: "rounded-md"
      },
      size: {
        xxs:     "h-4 w-4 text-xs",
        sm:      "h-6 w-6 text-xs",
        md:      "h-8 w-8 text-sm",
        default: "h-10 w-10 text-sm",
        lg:      "h-12 w-12 text-base",
        xl:      "h-16 w-16 text-lg"
      },
      color: {
        default:     "bg-muted text-foreground/70",
        primary:     "bg-primary text-primary-foreground",
        destructive: "bg-destructive text-white",
        amber:       "bg-amber-500 dark:bg-amber-600 text-white",
        emerald:     "bg-emerald-500 dark:bg-emerald-600 text-white",
        purple:      "bg-purple-500 dark:bg-purple-600 text-white",
        sky:         "bg-sky-500 dark:bg-sky-600 text-white"
      }
    },
    defaults: { shape: :circle, size: :default, color: :default }
  )

  renders_one :image, UI::Avatar::Image
  renders_one :fallback, UI::Avatar::Fallback

  def initialize(shape: :circle, size: :default, color: :default, alt: nil, class: nil, **html_attrs)
    @shape      = shape
    @size       = size
    @color      = color
    @alt        = alt
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(variant_classes(shape: @shape, size: @size, color: @color), @user_class)
  end

  def has_image?
    image? && @image.src.present?
  end

  def a11y_attrs
    return {} unless @alt
    { role: "img", "aria-label": @alt }
  end
end

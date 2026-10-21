# frozen_string_literal: true

class UI::Text < UI::Base
  variants(
    base: "leading-normal",
    variants: {
      size: {
        xs:   "text-xs",
        sm:   "text-sm",
        base: "text-base",
        lg:   "text-lg",
        xl:   "text-xl",
        "2xl": "text-2xl",
        "3xl": "text-3xl",
        "4xl": "text-4xl"
      },
      weight: {
        normal:   "font-normal",
        medium:   "font-medium",
        semibold: "font-semibold",
        bold:     "font-bold"
      },
      tone: {
        default:     "text-foreground",
        muted:       "text-muted-foreground",
        destructive: "text-destructive"
      }
    },
    defaults: { size: :base, weight: :normal, tone: :default }
  )

  def initialize(as: :p, size: :base, weight: :normal, tone: :default, class: nil, **html_attrs)
    @as          = binding.local_variable_get(:as)
    @size        = size
    @weight      = weight
    @tone        = tone
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  def classes
    cn(variant_classes(size: @size, weight: @weight, tone: @tone), @user_class)
  end

  def tag_name
    @as
  end
end

# frozen_string_literal: true

class UI::Label < UI::Base
  variants(
    base: "leading-none",
    variants: {
      size: {
        xs:      "text-xs",
        sm:      "text-sm",
        default: "text-sm",
        lg:      "text-base"
      },
      weight: {
        normal:   "font-normal",
        medium:   "font-medium",
        semibold: "font-semibold"
      }
    },
    defaults: { size: :default, weight: :medium }
  )

  def initialize(size: :default, weight: :medium,
                 required: false, disabled: false,
                 for: nil, class: nil, **html_attrs)
    @size     = size
    @weight   = weight
    @required = required
    @disabled = disabled
    @for      = binding.local_variable_get(:for)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(
      variant_classes(size: @size, weight: @weight),
      { "text-muted-foreground cursor-not-allowed" => @disabled },
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:for]   = @for if @for
    opts[:class] = classes
    opts
  end
end

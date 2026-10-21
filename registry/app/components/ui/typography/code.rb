# frozen_string_literal: true

class UI::Typography::Code < UI::Base
  variants(
    base: "relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold",
    variants: {
      size: {
        sm:   "text-xs",
        base: "text-sm",
        lg:   "text-base"
      }
    },
    defaults: { size: :base }
  )

  def initialize(size: :base, class: nil, **html_attrs)
    @size       = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(variant_classes(size: @size), @user_class)
  end
end

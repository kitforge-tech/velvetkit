# frozen_string_literal: true

class UI::Icon < UI::Base
  variants(
    base: "inline-block shrink-0",
    variants: {
      size: {
        xs:      "w-3 h-3",
        sm:      "w-4 h-4",
        default: "w-5 h-5",
        lg:      "w-6 h-6",
        xl:      "w-8 h-8"
      }
    },
    defaults: { size: :default }
  )

  def initialize(name:, size: :default, label: nil, class: nil, **html_attrs)
    @name = name
    @size = size
    @label = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def render?
    @name.present?
  end

  def classes
    cn(variant_classes(size: @size), @user_class)
  end

  def aria_attributes
    if @label
      { label: @label }
    else
      { hidden: true }
    end
  end
end

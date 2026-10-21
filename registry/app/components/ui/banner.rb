# frozen_string_literal: true

class UI::Banner < UI::Base
  variants(
    base: "relative flex gap-4 rounded-lg p-4",
    variants: {
      variant: {
        introduction: "bg-primary/10 border border-primary/20 text-foreground",
        promotion:    "bg-accent border border-accent-foreground/20 text-foreground"
      }
    },
    defaults: { variant: :introduction }
  )

  renders_one :illustration
  renders_one :leading_icon, ->(name:, **opts) {
    UI::Icon.new(name: name, size: :default, class: "shrink-0 mt-0.5", **opts)
  }
  renders_one :title, ->(**opts, &block) {
    tag.h4(class: "text-sm font-semibold mb-1", **opts, &block)
  }
  renders_one :action, ->(**opts, &block) {
    tag.div(class: "mt-3", **opts, &block)
  }

  def initialize(variant: :introduction, dismissible: true, full_width: false,
                 dismiss_icon: "x", class: nil, **html_attrs)
    @variant      = variant
    @dismissible  = dismissible
    @full_width   = full_width
    @dismiss_icon = dismiss_icon
    @user_class   = binding.local_variable_get(:class)
    @html_attrs   = html_attrs
  end

  def classes
    cn(
      variant_classes(variant: @variant),
      { "w-full" => @full_width },
      @user_class
    )
  end

  def dismissible?
    @dismissible
  end
end

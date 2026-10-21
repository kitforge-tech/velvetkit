# frozen_string_literal: true

class UI::Tooltip::Content < UI::Base
  # Note: do NOT add `overflow-hidden` here — Floating UI positions the arrow
  # partially outside this box via a negative `staticSide` offset, and
  # `overflow-hidden` would clip the arrow (the most common reason it goes
  # invisible). Keep overflow visible so the arrow can stick out.
  variants(
    base: "z-50 rounded-md bg-foreground px-3 py-1.5 text-sm text-background shadow-lg " \
          "animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 " \
          "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 " \
          "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
    variants: {
      side: {
        top: "",
        right: "",
        bottom: "",
        left: ""
      },
      align: {
        start: "",
        center: "",
        end: ""
      }
    },
    defaults: { side: :top, align: :center }
  )

  def initialize(side: :top, align: :center, class: nil, **html_attrs)
    @side = side
    @align = align
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_tooltip_context(tooltip)
    @tooltip = tooltip
    @id = @html_attrs[:id] || "ui-tooltip-content-#{tooltip.id}"
  end

  def classes
    cn(
      variant_classes(side: @side, align: @align),
      @user_class
    )
  end

  def arrow_classes
    "absolute w-2 h-2 bg-foreground rotate-45"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id] = @id
    opts[:class] = classes
    opts[:role] = :tooltip
    opts[:"data-ui--tooltip-target"] = "content"
    opts[:hidden] = true
    opts[:"data-side"] = @side
    opts[:"data-align"] = @align
    opts
  end

  attr_reader :side, :align
end

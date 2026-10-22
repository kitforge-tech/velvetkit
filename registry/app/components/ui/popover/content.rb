# frozen_string_literal: true

class UI::Popover::Content < UI::Base
  variants(
    base: "z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none " \
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

  renders_one :title

  def initialize(side: :top, align: :center, show_close: false, class: nil, **html_attrs)
    @side = side
    @align = align
    @show_close = show_close
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_popover_context(popover)
    @popover = popover
    @id = @html_attrs[:id] || "ui-popover-content-#{popover.id}"
  end

  def classes
    cn(
      variant_classes(side: @side, align: @align),
      @user_class
    )
  end

  # A square turned 45°, half inside the popover. Only its two outer edges
  # get a border, so it reads as the popover's outline stepping out to a
  # point; the inner half covers the popover's own border. Keyed on
  # data-side, which the controller updates when the popover flips.
  def arrow_classes
    "absolute size-2 rotate-45 bg-popover border-border " \
      "data-[side=top]:border-r data-[side=top]:border-b " \
      "data-[side=bottom]:border-l data-[side=bottom]:border-t " \
      "data-[side=left]:border-t data-[side=left]:border-r " \
      "data-[side=right]:border-b data-[side=right]:border-l"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id] = @id
    opts[:class] = classes
    opts[:role] = :dialog
    opts[:"aria-modal"] = false
    opts[:"aria-labelledby"] = "ui-popover-title-#{@popover.id}" if title?
    opts[:"data-ui--popover-target"] = "content"
    opts[:hidden] = true
    opts[:"data-side"] = @side
    opts[:"data-align"] = @align
    opts[:tabindex] = -1
    opts
  end

  def show_close?
    @show_close
  end

  def title_id
    "ui-popover-title-#{@popover.id}"
  end

  attr_reader :side, :align
end

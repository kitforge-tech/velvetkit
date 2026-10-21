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

  def arrow_classes
    # Arrow borders are driven by data-side attribute so they update when
    # Floating UI flips the popover position based on available viewport space.
    # Base: border-t border-l (arrow points down for data-side="top")
    # Overrides remove base borders and add the correct pointing-edge borders:
    #   data-side="bottom": remove t/l, add b/r (points up)
    #   data-side="left":   remove t/l, add b/l (points right)
    #   data-side="right":  remove t/l, add t/r (points left)
    "absolute w-2 h-2 bg-popover rotate-45 border-t border-l " \
    "data-[side=bottom]:border-b-0 data-[side=bottom]:border-r-0 data-[side=bottom]:border-b data-[side=bottom]:border-r " \
    "data-[side=left]:border-b-0 data-[side=left]:border-l-0 data-[side=left]:border-b data-[side=left]:border-r " \
    "data-[side=right]:border-t-0 data-[side=right]:border-r-0 data-[side=right]:border-b data-[side=right]:border-l"
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

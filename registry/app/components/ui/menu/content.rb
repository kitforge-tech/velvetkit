# frozen_string_literal: true

class UI::Menu::Content < UI::Base
  variants(
    base: "z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md flex flex-col gap-[5px] " \
          "animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 " \
          "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 " \
          "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
    variants: {
      side: {
        top: "",
        bottom: "",
        left: "",
        right: ""
      },
      align: {
        start: "",
        center: "",
        end: ""
      }
    },
    defaults: { side: :bottom, align: :start }
  )

  def initialize(side: :bottom, align: :start, class: nil, **html_attrs)
    @side = side
    @align = align
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @items = []
  end

  def set_menu_context(menu)
    @menu = menu
    @id = @html_attrs[:id] || "ui-menu-content-#{menu.id}"
  end

  def before_render
    content
  end

  def with_item(label = nil, href: nil, disabled: false, variant: :default, inset: false, **opts, &block)
    item_class = opts.delete(:class)
    @items << {
      type: :item,
      comp: UI::Menu::Item.new(
        label,
        href: href,
        disabled: disabled,
        variant: variant,
        inset: inset,
        class: item_class,
        **opts,
        &block
      )
    }
  end

  def with_label(label = nil, inset: false, **opts, &block)
    label_class = opts.delete(:class)
    @items << {
      type: :label,
      comp: UI::Menu::Label.new(
        label,
        inset: inset,
        class: label_class,
        **opts,
        &block
      )
    }
  end

  def with_divider(**opts)
    sep_class = opts.delete(:class)
    @items << {
      type: :separator,
      comp: UI::Menu::Separator.new(
        class: sep_class,
        **opts
      )
    }
  end

  def classes
    cn(
      variant_classes(side: @side, align: @align),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id] = @id
    opts[:class] = classes
    opts[:role] = :menu
    opts[:"aria-orientation"] = :vertical
    opts[:"data-ui--menu-target"] = "content"
    opts[:hidden] = true
    opts[:"data-side"] = @side
    opts[:"data-align"] = @align
    opts[:tabindex] = -1
    opts
  end

  attr_reader :side, :align, :items
end

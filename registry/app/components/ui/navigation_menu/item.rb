# frozen_string_literal: true

# UI::NavigationMenu::Item — one entry in the top row.
#
# With `with_link`s (or any block content) it is a trigger that opens a
# panel; without, give it `href:` and it is a plain link.
#
#   label:       the text in the top row
#   href:        makes it a plain link (ignored when it has a panel)
#   active:      marks the current section: aria-current="page" on a plain
#                link, a highlight on a trigger
#   columns:     1 or 2 columns of links in the panel
#   panel_class: extra classes for the panel, e.g. a width
class UI::NavigationMenu::Item < UI::Base
  TOP_ITEM = "group/nav-item inline-flex h-9 items-center justify-center gap-1 rounded-md px-3 " \
             "text-sm font-medium whitespace-nowrap text-foreground transition-colors " \
             "hover:bg-accent hover:text-accent-foreground " \
             "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1 " \
             "aria-expanded:bg-accent aria-expanded:text-accent-foreground " \
             "data-[active]:bg-accent/60 aria-[current=page]:bg-accent/60"

  renders_many :links, ->(title:, href:, **opts) { UI::NavigationMenu::Link.new(title: title, href: href, **opts) }

  def initialize(label:, href: nil, active: false, columns: 1, panel_class: nil, class: nil, **html_attrs)
    @label       = label
    @href        = href
    @active      = active
    @columns     = columns == 2 ? 2 : 1
    @panel_class = panel_class
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  attr_reader :label

  def set_navigation_context(nav, index:)
    @nav   = nav
    @index = index
  end

  def trigger_id; "#{@nav.id}-trigger-#{@index}"; end
  def panel_id;   "#{@nav.id}-panel-#{@index}";   end

  def li_options
    { class: cn("relative", @user_class), **@html_attrs }
  end

  def link_options
    {
      href: @href,
      class: TOP_ITEM,
      "aria-current": (@active ? "page" : nil),
      data: { "ui--navigation-menu-target": "top", action: "keydown->ui--navigation-menu#topKeydown" }
    }
  end

  def trigger_options
    {
      type: "button",
      id: trigger_id,
      class: TOP_ITEM,
      "aria-expanded": "false",
      "aria-controls": panel_id,
      data: {
        "ui--navigation-menu-target": "top trigger",
        active: (@active ? "" : nil),
        action: [
          "click->ui--navigation-menu#toggle",
          "pointerenter->ui--navigation-menu#hoverOpen",
          "pointerleave->ui--navigation-menu#hoverClose",
          "keydown->ui--navigation-menu#topKeydown"
        ].join(" ")
      }
    }
  end

  def panel_options
    {
      id: panel_id,
      hidden: true,
      class: cn(
        "z-50 max-w-[calc(100vw-1rem)] rounded-lg border bg-popover p-2 text-popover-foreground shadow-md",
        "animate-in fade-in-0 zoom-in-95",
        @columns == 2 ? "w-[36rem]" : "w-96",
        @panel_class
      ),
      data: {
        "ui--navigation-menu-target": "panel",
        state: "closed",
        action: [
          "pointerenter->ui--navigation-menu#cancelClose",
          "pointerleave->ui--navigation-menu#hoverClose",
          "keydown->ui--navigation-menu#panelKeydown"
        ].join(" ")
      }
    }
  end

  def list_classes
    cn("grid gap-1", { "sm:grid-cols-2" => @columns == 2 })
  end
end

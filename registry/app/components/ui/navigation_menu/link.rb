# frozen_string_literal: true

# UI::NavigationMenu::Link — a rich link in a panel: a title, an optional
# one- or two-line description and an optional leading icon.
#
#   title:       the link text
#   href:        where it goes
#   description: muted text under the title
#   icon:        a Lucide icon name, shown in a tile on the left
#   active:      the current page (aria-current="page")
class UI::NavigationMenu::Link < UI::Base
  def initialize(title:, href:, description: nil, icon: nil, active: false, class: nil, **html_attrs)
    @title       = title
    @href        = href
    @description = description
    @icon        = icon
    @active      = active
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  attr_reader :title, :description, :icon

  def link_options
    user_data = @html_attrs[:data] || {}
    @html_attrs.except(:data).merge(
      href: @href,
      class: cn(
        "flex gap-3 rounded-md p-3 text-sm outline-none transition-colors",
        # A title alone sits level with its icon; with a description, both
        # start at the top.
        @description ? "items-start" : "items-center",
        "hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent focus-visible:text-accent-foreground",
        "focus-visible:ring-2 focus-visible:ring-primary aria-[current=page]:bg-accent/60",
        @user_class
      ),
      "aria-current": (@active ? "page" : nil),
      data: user_data.merge("ui--navigation-menu-target": "link")
    )
  end
end

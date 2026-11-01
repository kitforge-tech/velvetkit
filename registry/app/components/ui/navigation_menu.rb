# frozen_string_literal: true

# UI::NavigationMenu — a site's main navigation: plain links, and triggers
# that open a panel of rich links (title, description, optional icon).
#
# Follows the WAI-ARIA disclosure navigation pattern (buttons with
# aria-expanded controlling a panel of ordinary links), not role="menu",
# which is for application menus.
#
#   <%= render(UI::NavigationMenu.new) do |nav| %>
#     <% nav.with_item(label: "Getting started") do |item| %>
#       <% item.with_link(title: "Introduction", href: "/docs",
#                         description: "Re-usable components built with Tailwind CSS.") %>
#     <% end %>
#     <% nav.with_item(label: "Docs", href: "/docs") %>
#   <% end %>
#
# A panel opens on hover (mouse, after `open_delay` ms; instantly when
# another panel is already open), on click, or with Enter/Space/ArrowDown.
# Escape, a click outside or tabbing away closes it.
#
# Compound:
#   UI::NavigationMenu         — the <nav> and its list
#   UI::NavigationMenu::Item   — a plain link, or a trigger plus its panel
#   UI::NavigationMenu::Link   — a rich link inside a panel
class UI::NavigationMenu < UI::Base
  renders_many :items, ->(label:, **opts) {
    @item_count = (@item_count || 0) + 1
    UI::NavigationMenu::Item.new(label: label, **opts).tap { |i| i.set_navigation_context(self, index: @item_count) }
  }

  # label:       accessible name of the <nav> (several navs on a page need
  #              different names)
  # open_delay:  ms of hovering before a panel opens
  # close_delay: ms after the pointer leaves before it closes, so it can
  #              cross the gap between trigger and panel
  def initialize(label: nil, open_delay: 150, close_delay: 200, class: nil, **html_attrs)
    @label       = label
    @open_delay  = open_delay
    @close_delay = close_delay
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
    @id          = @html_attrs.delete(:id) || "ui-navigation-menu-#{SecureRandom.hex(4)}"
  end

  attr_reader :id

  def nav_label
    @label || t("ui.navigation_menu.label", default: "Main")
  end

  def root_classes
    cn("relative", @user_class)
  end

  def root_data
    {
      controller: "ui--navigation-menu",
      "ui--navigation-menu-open-delay-value": @open_delay,
      "ui--navigation-menu-close-delay-value": @close_delay,
      action: "focusin->ui--navigation-menu#focusIn focusout->ui--navigation-menu#focusOut"
    }.merge(@html_attrs[:data] || {})
  end
end

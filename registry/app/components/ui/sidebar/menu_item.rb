# frozen_string_literal: true

# One entry in a sidebar menu: a `menu_button`, and optionally a `sub_menu` of
# links under it, such as a list of albums. The sub-menu has a button of its
# own to open and close it, beside the link, so the link still goes to its
# page. It starts open when `open:` says so, or when one of its links is the
# current page.
class UI::Sidebar::MenuItem < UI::Base
  renders_one :menu_button, UI::Sidebar::MenuButton
  renders_one :sub_menu, UI::Sidebar::MenuSub

  def initialize(open: nil, **system_args)
    @open = open
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-menu-item"
    @system_args[:data][:sidebar] = "menu-item"

    @system_args[:class] = class_names(
      "group/menu-item relative",
      # Active indicator: a primary bar flush with the sidebar edge, for the
      # default shape only; a pill is filled in instead.
      "before:absolute before:-start-2 before:top-4 before:h-6 before:w-1 " \
      "before:-translate-y-1/2 before:rounded-e-full before:bg-sidebar-primary " \
      "before:opacity-0 before:transition-opacity " \
      "has-[>[data-active=true][data-shape=default]]:before:opacity-100",
      @system_args[:class]
    )
  end

  def sub_menu_id = @sub_menu_id ||= "sidebar-sub-#{SecureRandom.hex(4)}"

  # Drawn first, so it knows whether one of its links is the current page.
  def sub_menu_html
    sub_menu.configure(id: sub_menu_id, open: @open)
    sub_menu.to_s
  end

  def toggle_attrs
    { type: "button", data: { sidebar: "menu-action", action: "ui--sidebar#toggleSub" },
      aria: { expanded: sub_menu.open?.to_s, controls: sub_menu_id,
              label: t("ui.sidebar.toggle_sub", name: sub_menu.name, default: "Show the links under %{name}") },
      class: "absolute end-1 top-1 flex size-6 items-center justify-center rounded-md text-sidebar-foreground/70 outline-hidden " \
             "ring-sidebar-ring hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 " \
             "group-data-[collapsible=icon]:hidden group-has-[>[data-shape=pill]]/menu-item:top-2 " \
             "[&[aria-expanded=true]>svg]:rotate-90 [&>svg]:transition-transform motion-reduce:[&>svg]:transition-none" }
  end
end

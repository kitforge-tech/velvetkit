# frozen_string_literal: true

# An app's sidebar: a header, groups of links, and a footer, beside the page's
# content (`UI::Sidebar::Inset`), both inside a `UI::Sidebar::Wrapper`.
#
#   <%= render(UI::Sidebar::Wrapper.new) do %>
#     <%= render(UI::Sidebar.new(id: "app-sidebar", collapsible: :icon)) do |sidebar| %>
#       <% sidebar.with_sidebar_content do |content| %>
#         <% content.with_sidebar_group do |group| %>
#           <% group.with_menu do |menu| %>
#             <% menu.with_menu_item do |item| %>
#               <% item.with_menu_button(photos_path, active: true, shape: :pill) do %>…<% end %>
#             <% end %>
#           <% end %>
#         <% end %>
#       <% end %>
#     <% end %>
#     <%= render(UI::Sidebar::Inset.new) do %>
#       <%= render(UI::Sidebar::Trigger.new(sidebar_id: "app-sidebar")) %> …
#     <% end %>
#   <% end %>
#
# `collapsible:` says what the trigger does on a wide screen: :icon shrinks the
# sidebar to its icons, :offcanvas slides it away, and :none keeps it open.
# `state:` is whether it starts :expanded or :collapsed. Left out, it's what the
# reader last chose, kept in a cookie so the page is drawn that way from the
# start rather than changing once it loads.
#
# On a phone the sidebar is a drawer over the page, closed until the trigger
# opens it, whatever `collapsible:` says. Escape, the backdrop, or following a
# link closes it.
#
# The sidebar sticks to the top of the window and is as tall as it, or as the
# wrapper when that's shorter, so a bar above the app doesn't push its footer
# out of sight: give the wrapper a height (`class: "h-[calc(100svh-3rem)]"`).
class UI::Sidebar < UI::Base
  COLLAPSIBLE = %i[icon offcanvas none].freeze
  STATES = %i[expanded collapsed].freeze

  renders_one :sidebar_header, UI::Sidebar::Header
  renders_one :sidebar_content, UI::Sidebar::Content
  renders_one :sidebar_footer, UI::Sidebar::Footer

  def initialize(collapsible: :icon, variant: :sidebar, side: :left, state: nil, **system_args)
    @collapsible = COLLAPSIBLE.include?(collapsible.to_sym) ? collapsible.to_sym : :icon
    @variant = variant
    @side = side
    @state = state&.to_sym
    @system_args = system_args
  end

  # The cookie the controller writes the reader's choice to, one per sidebar.
  def self.cookie_name(id) = "ui_sidebar_#{id.presence || 'state'}".tr("-", "_")

  def before_render
    @system_args[:data] = (@system_args[:data] || {}).merge(
      slot: "sidebar", variant: @variant, side: @side, state: state,
      # What the sidebar is doing now: "icon" or "offcanvas" while collapsed,
      # empty while open. The styles hang off this.
      collapsible: (state == :collapsed ? @collapsible : ""),
      collapsible_mode: @collapsible,
      "ui--sidebar-target": "sidebar",
      cookie: self.class.cookie_name(@system_args[:id])
    )
    @system_args[:class] = cn(
      "group peer shrink-0 text-sidebar-foreground w-0 md:w-(--sidebar-width) md:transition-[width] md:duration-200 md:ease-linear",
      "md:data-[collapsible=icon]:w-(--sidebar-width-icon) md:data-[collapsible=offcanvas]:w-0 data-[side=right]:order-last",
      @system_args[:class]
    )
  end

  def state
    return :collapsed if @collapsible != :none && @state == :collapsed
    return :expanded if @state || @collapsible == :none

    saved = helpers.request&.cookies&.[](self.class.cookie_name(@system_args[:id]))
    saved == "collapsed" ? :collapsed : :expanded
  rescue NoMethodError
    :expanded
  end

  # A drawer on a phone, beside the content from `md` up.
  def container_classes
    cn(
      "fixed inset-y-0 start-0 z-50 flex w-(--sidebar-width-mobile) max-w-[85vw] invisible",
      "-translate-x-full rtl:translate-x-full group-data-[side=right]:start-auto group-data-[side=right]:end-0",
      "group-data-[side=right]:translate-x-full transition-[translate,visibility] duration-200 ease-out",
      "group-data-[mobile=open]:visible group-data-[mobile=open]:translate-x-0 motion-reduce:transition-none",
      "md:visible md:sticky md:top-0 md:z-10 md:h-svh md:max-h-full md:w-(--sidebar-width) md:translate-x-0",
      "md:transition-[width,translate] md:group-data-[collapsible=icon]:w-(--sidebar-width-icon)",
      "md:group-data-[collapsible=offcanvas]:-translate-x-full md:group-data-[collapsible=offcanvas]:invisible!",
      "md:group-data-[side=left]:border-e md:group-data-[side=right]:border-s",
      "md:group-data-[variant=floating]:border-0 md:group-data-[variant=inset]:border-0",
      "md:group-data-[variant=floating]:p-2 md:group-data-[variant=inset]:p-2"
    )
  end

  def backdrop_classes
    "fixed inset-0 z-40 bg-black/50 invisible opacity-0 transition-[opacity,visibility] duration-200 " \
      "group-data-[mobile=open]:visible group-data-[mobile=open]:opacity-100 motion-reduce:transition-none md:hidden"
  end
end

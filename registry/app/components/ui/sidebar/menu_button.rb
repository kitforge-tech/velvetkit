# frozen_string_literal: true

# A link in the sidebar. `active: true` marks the page being shown, for screen
# readers too (aria-current="page").
#
# `shape:` is :default, a compact row with a bar at the sidebar's edge for the
# current page, or :pill, a taller row whose current page is filled in edge to
# edge, rounded at both ends.
class UI::Sidebar::MenuButton < UI::Base
  SHAPES = {
    default: "h-8 rounded-md p-2 data-[active=true]:bg-sidebar-primary/10",
    pill: "h-10 gap-3 rounded-full px-4 data-[active=true]:bg-sidebar-primary/15 group-data-[collapsible=icon]:rounded-full!"
  }.freeze

  def initialize(path, active: false, current: nil, shape: :default, icon: nil, **system_args) # rubocop:disable Lint/UnusedMethodArgument
    @path = path
    @is_active = active
    @shape = SHAPES.key?(shape.to_sym) ? shape.to_sym : :default
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-menu-button"
    @system_args[:data][:sidebar] = "menu-button"
    @system_args[:data][:active] = @is_active.to_s
    @system_args[:data][:shape] = @shape

    # An explicit `current:` always wins; an active button falls back to "page"
    # so assistive tech announces it without the caller repeating themselves.
    aria_current = current || ("page" if @is_active)
    if aria_current
      @system_args[:aria] = (@system_args[:aria] || {}).merge(current: aria_current)
    end

    @system_args[:class] = cn(
      "peer/menu-button flex w-full items-center gap-2 overflow-hidden text-left text-sm outline-hidden ring-sidebar-ring " \
      "transition-[width,height,padding] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 " \
      "active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 " \
      "group-has-data-[sidebar=menu-action]/menu-item:pe-8 aria-disabled:pointer-events-none aria-disabled:opacity-50 " \
      "data-[active=true]:font-semibold data-[active=true]:text-sidebar-primary data-[active=true]:[&>svg]:stroke-current " \
      "group-data-[collapsible=icon]:size-8! group-data-[collapsible=icon]:p-2! [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0",
      SHAPES[@shape],
      @system_args[:class]
    )
  end
end

# frozen_string_literal: true

class UI::Sidebar::MenuButton < ViewComponent::Base
  def initialize(path, active: false, current: nil, icon: nil, **system_args)
    @path = path
    @is_active = active

    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-menu-button"
    @system_args[:data][:sidebar] = "menu-button"
    @system_args[:data][:active] = @is_active.to_s

    # An explicit `current:` always wins; an active button falls back to "page"
    # so assistive tech announces it without the caller repeating themselves.
    aria_current = current || ("page" if @is_active)
    if aria_current
      @system_args[:aria] = (@system_args[:aria] || {}).merge(current: aria_current)
    end

    @system_args[:class] = class_names(
      "peer/menu-button flex w-full items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm outline-hidden ring-sidebar-ring transition-[width,height,padding] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 group-has-data-[sidebar=menu-action]/menu-item:pr-8 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[active=true]:bg-sidebar-primary/10 data-[active=true]:font-semibold data-[active=true]:text-sidebar-primary data-[active=true]:[&>svg]:stroke-current data-[state=open]:hover:bg-sidebar-accent data-[state=open]:hover:text-sidebar-accent-foreground group-data-[collapsible=icon]:size-8! group-data-[collapsible=icon]:p-2! [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0",
      "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
      "h-8 text-sm",
      @system_args[:class],
      "bg-accent" => @is_active
    )
  end
end

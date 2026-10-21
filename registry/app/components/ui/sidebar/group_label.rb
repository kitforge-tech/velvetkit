# frozen_string_literal: true

class UI::Sidebar::GroupLabel < ViewComponent::Base
  def initialize(label, **system_args)
    @label = label
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-group-label"
    @system_args[:data][:sidebar] = "group-label"

    @system_args[:class] = class_names(
      "text-sidebar-foreground/70 ring-sidebar-ring flex h-8 shrink-0 items-center rounded-md px-2 text-xs font-medium outline-hidden transition-[margin,opacity] duration-200 ease-linear focus-visible:ring-2 [&>svg]:size-4 [&>svg]:shrink-0",
      "group-data-[collapsible=icon]:-mt-8 group-data-[collapsible=icon]:opacity-0",
      @system_args[:class]
    )
  end
end

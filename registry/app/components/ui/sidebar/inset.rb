# frozen_string_literal: true

class UI::Sidebar::Inset < UI::Base
  def initialize(**system_args)
    @system_args = system_args
    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-inset"
  end

  def before_render
    @system_args[:class] = class_names(
      "bg-background relative flex w-full flex-1 flex-col",
      "md:peer-data-[variant=inset]:m-2 md:peer-data-[variant=inset]:ml-0 md:peer-data-[variant=inset]:rounded-xl md:peer-data-[variant=inset]:shadow-sm md:peer-data-[variant=inset]:peer-data-[state=collapsed]:ml-2",
      @system_args[:class]
    )
  end
end

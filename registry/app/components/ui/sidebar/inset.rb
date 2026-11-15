# frozen_string_literal: true

class UI::Sidebar::Inset < UI::Base
  def initialize(**system_args)
    @system_args = system_args
    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-inset"
  end

  # cn, not class_names: a class passed in replaces the one it clashes with
  # (bg-transparent for bg-background, shadow-none for shadow-sm), rather than
  # both landing on the element and CSS order picking one.
  def before_render
    @system_args[:class] = cn(
      "bg-background relative flex w-full min-w-0 flex-1 flex-col",
      "md:peer-data-[variant=inset]:m-2 md:peer-data-[variant=inset]:ml-0 md:peer-data-[variant=inset]:rounded-xl md:peer-data-[variant=inset]:shadow-sm md:peer-data-[variant=inset]:peer-data-[state=collapsed]:ml-2",
      @system_args[:class]
    )
  end
end

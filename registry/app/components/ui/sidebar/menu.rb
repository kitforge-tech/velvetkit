# frozen_string_literal: true

class UI::Sidebar::Menu < UI::Base
  renders_many :menu_items, UI::Sidebar::MenuItem

  def initialize(**system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-menu"
    @system_args[:data][:sidebar] = "menu"

    @system_args[:class] = class_names(
      "flex w-full min-w-0 flex-col gap-1",
      @system_args[:class]
    )
  end
end

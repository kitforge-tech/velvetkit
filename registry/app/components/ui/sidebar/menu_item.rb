# frozen_string_literal: true

class UI::Sidebar::MenuItem < UI::Base
  renders_one :menu_button, UI::Sidebar::MenuButton

  def initialize(**system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-menu-item"
    @system_args[:data][:sidebar] = "menu-item"

    @system_args[:class] = class_names(
      "group/menu-item relative",
      # Active indicator: a primary bar flush with the sidebar edge.
      "before:absolute before:-left-2 before:top-1/2 before:h-6 before:w-1 " \
      "before:-translate-y-1/2 before:rounded-r-full before:bg-sidebar-primary " \
      "before:opacity-0 before:transition-opacity " \
      "has-[[data-active=true]]:before:opacity-100",
      @system_args[:class]
    )
  end
end

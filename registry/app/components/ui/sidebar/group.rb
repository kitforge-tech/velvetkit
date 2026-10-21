# frozen_string_literal: true

class UI::Sidebar::Group < UI::Base
  renders_one :label, UI::Sidebar::GroupLabel
  renders_one :menu, UI::Sidebar::Menu

  def initialize(**system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-group"
    @system_args[:data][:sidebar] = "group"

    @system_args[:class] = class_names(
      "relative flex w-full min-w-0 flex-col p-2",
      @system_args[:class]
    )
  end
end

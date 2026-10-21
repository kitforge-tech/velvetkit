# frozen_string_literal: true

class UI::Sidebar::Header < UI::Base
  def initialize(**system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-header"
    @system_args[:data][:sidebar] = "sidebar"

    @system_args[:class] = class_names(
      "flex flex-col gap-2 p-2",
      @system_args[:class]
    )
  end
end

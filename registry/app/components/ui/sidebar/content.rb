# frozen_string_literal: true

class UI::Sidebar::Content < UI::Base
  renders_many :sidebar_groups, UI::Sidebar::Group

  def initialize(**system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-content"
    @system_args[:data][:sidebar] = "content"

    @system_args[:class] = class_names(
      "flex min-h-0 flex-1 flex-col gap-2 overflow-auto group-data-[collapsible=icon]:overflow-hidden",
      @system_args[:class]
    )
  end
end

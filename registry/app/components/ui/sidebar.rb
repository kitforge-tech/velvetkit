# frozen_string_literal: true

class UI::Sidebar < UI::Base
  renders_one :sidebar_header, UI::Sidebar::Header
  renders_one :sidebar_content, UI::Sidebar::Content
  renders_one :sidebar_footer, UI::Sidebar::Footer

  def initialize(collapsible: :none, variant: :sidebar, side: :left, state: :expanded, **system_args)
    @collapsible = collapsible
    @variant = variant
    @side = side
    @state = state
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar"
    @system_args[:data][:variant] = @variant
    @system_args[:data][:collapsible] = @collapsible
    @system_args[:data][:side] = @side
    @system_args[:data][:state] = @state
    @system_args[:data]["ui--sidebar-target"] = "sidebar"


    @system_args[:class] = class_names(
      "group peer text-sidebar-foreground md:block",
      @system_args[:class]
    )
  end
end

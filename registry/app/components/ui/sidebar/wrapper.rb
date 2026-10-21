# frozen_string_literal: true

class UI::Sidebar::Wrapper < UI::Base
  SIDEBAR_WIDTH = "16rem"
  SIDEBAR_WIDTH_MOBILE = "18rem"
  SIDEBAR_WIDTH_ICON = "3rem"

  # Written out in full so Tailwind's source scanner can see each class literally;
  # an interpolated "min-h-#{...}" is invisible to it and never gets generated.
  MIN_HEIGHTS = {
    svh: "min-h-svh",
    dvh: "min-h-dvh",
    lvh: "min-h-lvh",
    screen: "min-h-screen",
    full: "min-h-full",
    none: nil
  }.freeze

  def initialize(min_height: :svh, **system_args)
    unless MIN_HEIGHTS.key?(min_height)
      raise ArgumentError, "min_height must be one of #{MIN_HEIGHTS.keys.join(', ')} (got #{min_height.inspect})"
    end

    @min_height = min_height
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:slot] = "sidebar-wrapper"
    @system_args[:data][:controller] = "ui--sidebar"

    @system_args[:style] ||= {}
    @system_args[:style] = "--sidebar-width: #{SIDEBAR_WIDTH}; --sidebar-width-mobile: #{SIDEBAR_WIDTH_MOBILE}; --sidebar-width-icon: #{SIDEBAR_WIDTH_ICON}"

    @system_args[:class] = class_names(
      "group/sidebar-wrapper has-data-[variant=inset]:bg-sidebar flex w-full",
      MIN_HEIGHTS[@min_height],
      @system_args[:class]
    )
  end
end

# frozen_string_literal: true

class UI::Sidebar::Trigger < UI::Base
  def initialize(sidebar_id: nil, expanded: true, label: nil, **system_args)
    @system_args = system_args

    @system_args[:data] ||= {}
    @system_args[:data][:action] = "ui--sidebar#toggle"
    @system_args[:data]["ui--sidebar-target"] = "trigger"

    # The icon-only button needs an accessible name, and screen readers need to
    # know which region it controls and whether that region is currently open.
    @system_args[:aria] = {
      controls: sidebar_id,
      expanded: expanded.to_s,
      label: label || I18n.t("ui.sidebar.toggle", default: "Toggle sidebar")
    }.compact.merge(@system_args[:aria] || {})

    @system_args[:class] = class_names(
      "size-7!",
      @system_args[:class]
    )
  end
end

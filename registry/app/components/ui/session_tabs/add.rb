# frozen_string_literal: true

# UI::SessionTabs::Add — the "+" button after the tabs.
#
#   url: POSTs a real form there (works without JS; Turbo disables the button
#        while the request is in flight, so a double click opens one tab).
#        Omit it to only dispatch `ui--session-tabs:add`.
#   label: accessible name; defaults to the "New tab" translation.
class UI::SessionTabs::Add < UI::Base
  def initialize(url: nil, label: nil, class: nil, **html_attrs)
    @url        = url
    @label      = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_session_tabs_context(tabs)
    @tabs = tabs
  end

  def url?
    @url.present?
  end

  attr_reader :url

  def label
    @label || t("ui.session_tabs.add", default: "New tab")
  end

  def touch?
    @tabs.size == :touch
  end

  def icon_size
    touch? ? :sm : :xs
  end

  def button_options
    user_data = @html_attrs[:data] || {}
    @html_attrs.except(:data).merge(
      variant: :ghost,
      size: :icon_sm,
      class: cn("mb-1 shrink-0", touch? ? "size-8" : "size-7", @user_class),
      "aria-label": label,
      title: label,
      data: user_data.merge(
        action: [ user_data[:action], "click->ui--session-tabs#add" ].compact.join(" ")
      )
    )
  end
end

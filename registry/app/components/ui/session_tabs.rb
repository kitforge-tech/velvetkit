# frozen_string_literal: true

# UI::SessionTabs — tabs the *user* manages: open, rename, duplicate, reorder,
# close — a browser-style tab bar over records the app keeps. (For a fixed set
# of panels the developer defines, use UI::Tabs.)
#
# The component never stores tabs. Each tab is either:
#   - a link (`href:`) — the server decides which tab is active, or
#   - a button (`value:` only) — the page reacts to `ui--session-tabs:select`.
#
# Each action (rename, duplicate, move, close) is opt-in per tab and takes
# either a URL — submitted as a Turbo form (PATCH/POST/PATCH/DELETE) — or
# `true`, in which case only the event fires and the app does the work.
# Every action dispatches a cancelable `ui--session-tabs:<action>` event
# first; `preventDefault()` stops it.
#
# Compound:
#   UI::SessionTabs        — the bar, the confirm-close dialog
#   UI::SessionTabs::Tab   — one tab + its options menu
#   UI::SessionTabs::Add   — the "+" button
class UI::SessionTabs < UI::Base
  renders_many :tabs, ->(value:, **opts) {
    UI::SessionTabs::Tab.new(value: value, **opts).tap do |t|
      t.set_session_tabs_context(self)
      (@tab_components ||= []) << t
    end
  }
  renders_one :add, ->(**opts) {
    UI::SessionTabs::Add.new(**opts).tap { |a| a.set_session_tabs_context(self) }
  }

  SIZES = %i[default touch].freeze

  # label:        accessible name of the tablist
  # size:         :default, or :touch for 44px-tall touch targets
  # min_tabs:     Close is hidden while this many tabs (or fewer) remain
  # return_focus: CSS selector focused after an action, so typing goes back
  #               to the page's main input instead of staying on the tab bar
  # rename_param: form field name the new label is submitted under
  def initialize(label: nil, size: :default, min_tabs: 1, return_focus: nil,
                 rename_param: "name", class: nil, **html_attrs)
    @label        = label
    @size         = SIZES.include?(size) ? size : :default
    @min_tabs     = min_tabs
    @return_focus = return_focus
    @rename_param = rename_param
    @user_class   = binding.local_variable_get(:class)
    @html_attrs   = html_attrs
    @id           = @html_attrs.delete(:id) || "ui-session-tabs-#{SecureRandom.hex(4)}"
  end

  attr_reader :id, :size, :min_tabs

  def touch?
    @size == :touch
  end

  # Read by each tab to decide whether Close is offered at render time; the
  # controller keeps it in sync as tabs come and go client-side.
  def closable_count?
    tabs.size > @min_tabs
  end

  # Tabs without `move:` stay put: Move left/right (and dragging) only swap
  # with movable tabs, so a fixed first tab stays first.
  def movable_neighbour?(tab, step)
    list = @tab_components || []
    i = list.index(tab) || 0
    others = step.negative? ? list[0...i] : list[(i + 1)..]
    others.any?(&:movable?)
  end

  def tablist_label
    @label || t("ui.session_tabs.label", default: "Open tabs")
  end

  def dialog_id
    "#{@id}-confirm"
  end

  def root_classes
    # The bottom rule is an inset shadow, painted beneath the tabs, so the
    # active tab's background covers it without overflow tricks.
    cn("flex w-full min-w-0 items-end gap-1 shadow-[inset_0_-1px_0_var(--color-border)]", @user_class)
  end

  def tablist_classes
    "flex min-w-0 items-end gap-1 overflow-x-auto overflow-y-hidden " \
      "[scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
  end

  def root_data
    {
      controller: "ui--session-tabs",
      "ui--session-tabs-min-tabs-value": @min_tabs,
      "ui--session-tabs-return-focus-value": @return_focus.to_s,
      "ui--session-tabs-rename-param-value": @rename_param,
      "ui--session-tabs-rename-label-value": t("ui.session_tabs.rename_label", default: "Tab name")
    }.merge(@html_attrs[:data] || {})
  end
end

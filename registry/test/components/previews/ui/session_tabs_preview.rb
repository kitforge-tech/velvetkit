# frozen_string_literal: true

# Tabs the user manages: rename, duplicate, reorder, close, add.
#
# Each action is opt-in per tab and takes either a URL (submitted as a Turbo
# form — rename PATCH, duplicate POST, move PATCH with a 1-based `position`,
# close DELETE) or `true` (only the cancelable `ui--session-tabs:<action>`
# event fires). These previews use events only, so nothing is saved.
class UI::SessionTabsPreview < ViewComponent::Preview
  # @label Playground
  # @param size     select { choices: [default, touch] }
  # @param min_tabs number
  # @param rename    toggle
  # @param duplicate toggle
  # @param move      toggle
  # @param close     toggle
  def playground(size: :default, min_tabs: 1, rename: true, duplicate: true, move: true, close: true)
    render(UI::SessionTabs.new(size: size.to_sym, min_tabs: min_tabs.to_i)) do |tabs|
      %w[Default Drafts Archive].each_with_index do |name, i|
        tabs.with_tab(value: name.downcase, active: i.zero?,
                      rename: rename, duplicate: duplicate, move: move, close: close) { name }
      end
      tabs.with_add
    end
  end

  # @label Saved views
  def saved_views; render_with_template; end

  # @label Touch, with close confirmation
  def touch_with_confirmation; render_with_template; end

  # @label Handling the events
  def handling_events; render_with_template; end
end

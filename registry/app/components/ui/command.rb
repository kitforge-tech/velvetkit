# frozen_string_literal: true

require "securerandom"

# A search box over everything you can do or go to: pages, actions, and, with
# `url:`, records from the server. Type to narrow it, arrows to move, Enter to
# go. On a page as it is, or `dialog: true` for the ⌘K kind, over the page.
#
#   <%= render(UI::Command.new(dialog: true, url: search_path)) do |command| %>
#     <% command.with_trigger %>
#     <% command.with_group(heading: "Pages") do |group| %>
#       <% group.with_item(label: "Dashboard", href: dashboard_path, icon: "house") %>
#       <% group.with_item(label: "Settings", href: settings_path, icon: "settings", shortcut: "mod+,") %>
#     <% end %>
#     <% command.with_group(heading: "Actions") do |group| %>
#       <% group.with_item(label: "New invoice", value: "new-invoice", icon: "plus", keywords: "create bill") %>
#     <% end %>
#   <% end %>
#
# An item with `href:` is visited (with Turbo when it's there; ⌘ or Ctrl+Enter
# opens a new tab). Every pick fires `ui--command:select` with its value,
# label and href first; cancel it to handle the pick yourself.
#
# Typing filters the items on the page by label and `keywords:`, best matches
# first, every word counting. With `url:` it also asks the server, as UI::Select
# does: GET url?q=… returning [{ label, href, value, description, group }],
# listed under `group`, or "Results". Searches are spaced out, a slow one shows
# a spinner, and answers are remembered for a minute.
#
# The dialog opens on `shortcut:` (mod+k) from anywhere on the page, from the
# trigger, or from any element with data-action="ui--command#open" inside it.
# `shortcut:` can be a list, like ["mod+k", "/"]; the trigger shows the first.
#
# `sort_groups: true` puts the group with the best match first, so a strong
# match isn't buried under a weak one in an earlier group. `empty:` says what
# to show when nothing matches. After each search it fires
# `ui--command:search` with the query and how many items match, for
# analytics, say.
class UI::Command < UI::Base
  renders_many :groups, "UI::Command::Group"

  # The button that opens the dialog: "Search…" and the shortcut, unless a
  # block says otherwise. Takes UI::Button's options.
  renders_one :trigger, lambda { |label: nil, **opts, &block|
    content = block ? view_context.capture(&block) : default_trigger_content(label)
    actions = [ "ui--command#open", opts.dig(:data, :action) ].compact.join(" ")
    render(UI::Button.new(variant: :outline, **opts,
                          class: cn("justify-between gap-6 font-normal text-muted-foreground", opts[:class]),
                          aria: { haspopup: "dialog", **(opts[:aria] || {}) },
                          data: { **(opts[:data] || {}), action: actions })) { content }
  }

  # The dialog sits near the top, where the eye already is, and doesn't jump
  # as the list shrinks.
  DIALOG = "fixed inset-0 m-0 p-0 max-w-none max-h-none w-full h-full bg-transparent border-0 overflow-visible " \
           "open:flex open:items-start open:justify-center open:px-4 open:pt-[12vh] " \
           "backdrop:bg-black/50 backdrop:backdrop-blur-[1px]"

  PANEL = "flex w-full flex-col overflow-hidden rounded-lg border bg-popover text-popover-foreground"

  def initialize(placeholder: nil, dialog: false, shortcut: "mod+k", url: nil, param: "q", results_heading: nil,
                 label: nil, empty: nil, sort_groups: false, class: nil, **html_attrs)
    @placeholder     = placeholder
    @dialog          = dialog
    @shortcuts       = Array(shortcut).map(&:to_s).reject(&:empty?)
    @empty           = empty
    @sort_groups     = sort_groups
    @url             = url
    @param           = param
    @results_heading = results_heading
    @label           = label
    @user_class      = binding.local_variable_get(:class)
    @html_attrs      = html_attrs
    @id              = html_attrs[:id] || "ui-command-#{SecureRandom.hex(4)}"
  end

  attr_reader :id

  # The one the trigger shows.
  def shortcut = @shortcuts.first

  def dialog? = @dialog
  def remote? = @url.present?

  def listbox_id = "#{id}-list"
  def input_id = "#{id}-input"

  def placeholder = @placeholder || t("ui.command.placeholder", default: "Type a command or search…")
  def label = @label || t("ui.command.label", default: "Command menu")
  def results_heading = @results_heading || t("ui.command.results", default: "Results")

  def root_attrs
    { **@html_attrs.except(:id), id: id, class: cn(!dialog? && "w-full", @user_class),
      data: { controller: "ui--command", **controller_values, **(@html_attrs[:data] || {}) } }
  end

  def panel_class = cn(PANEL, dialog? ? "max-w-xl shadow-2xl max-h-[min(32rem,76vh)]" : "shadow-sm")

  private

  def default_trigger_content(label)
    safe_join([
      tag.span(class: "flex items-center gap-2") do
        safe_join([ render(UI::Icon.new(name: "search", size: :sm)), label || t("ui.command.trigger", default: "Search…") ])
      end,
      (render(UI::Kbd.new(shortcut, size: :sm)) if shortcut)
    ])
  end

  def controller_values
    # Shortcuts never have spaces ("space" is the key), so they're listed with them.
    values = { "ui--command-dialog-value": dialog?, "ui--command-shortcut-value": (dialog? ? @shortcuts.join(" ") : ""),
               "ui--command-sort-groups-value": @sort_groups,
               "ui--command-empty-value": @empty || t("ui.command.empty", default: "No results found."),
               "ui--command-searching-value": t("ui.command.searching", default: "Searching…"),
               "ui--command-failed-value": t("ui.command.failed", default: "Couldn't search. Try again.") }
    return values unless remote?

    values.merge("ui--command-url-value": @url, "ui--command-param-value": @param,
                 "ui--command-results-heading-value": results_heading)
  end
end

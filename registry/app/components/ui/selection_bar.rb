# frozen_string_literal: true

# What to do with the things chosen on a page: "3 selected", a button to clear
# them, and the actions that work on all of them at once.
#
#   <%= render(UI::SelectionBar.new(for: "customers")) do |bar| %>
#     <% bar.with_action do %>
#       <%= render(UI::Button.new(variant: :ghost, type: :submit, form: "bulk", formaction: export_customers_path)) { "Export" } %>
#     <% end %>
#   <% end %>
#
# `for:` is the id of what holds the checkboxes: a `UI::Table` with
# `selection:`, or any list whose boxes carry `data-selection="item"` (and one
# with `data-selection="all"` to choose them all). The bar shows once one is
# checked and hides when none are, keeps "select all" checked, unchecked or
# partly checked to match, and lets Shift-click check a run of them. Escape
# or the clear button unchecks them all.
#
# An "all" box inside an element with `data-selection-group` chooses only the
# items in it: a day's photos under that day's heading.
#
# The boxes post like any checkbox, so an action is a submit button for the
# form they belong to (`form:` and `formaction:` on the button, `form:` on the
# table). A `selection-bar:change` event carries the count and the values, for
# a page that does more.
#
# `placement:` is :top, a bar that sticks to the top of its scrolling area, or
# :floating, a rounded bar near the bottom of the window.
class UI::SelectionBar < UI::Base
  PLACEMENTS = {
    top: "sticky top-0 z-30 flex h-14 w-full items-center gap-2 border-b bg-background/95 px-2 backdrop-blur " \
         "supports-[backdrop-filter]:bg-background/80 sm:px-4",
    floating: "fixed inset-x-4 bottom-4 z-40 mx-auto flex w-auto max-w-xl items-center gap-2 rounded-full border " \
              "bg-popover py-1.5 ps-1.5 pe-2 text-popover-foreground shadow-lg sm:inset-x-0 sm:w-fit"
  }.freeze

  renders_many :actions

  def initialize(for:, placement: :top, label: nil, class: nil, **html_attrs)
    @for        = binding.local_variable_get(:for)
    @placement  = PLACEMENTS.key?(placement.to_sym) ? placement.to_sym : :top
    @label      = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:role] = "region"
    attrs[:hidden] = true
    attrs[:class] = cn(PLACEMENTS[@placement], "[&[hidden]]:hidden", @user_class)
    attrs[:aria] = { label: @label || t("ui.selection_bar.label", default: "Selection") }.merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "selection-bar", placement: @placement, controller: "ui--selection-bar",
                     "ui--selection-bar-for-value": @for,
                     "ui--selection-bar-one-value": t("ui.selection_bar.count.one", default: "%{count} selected"),
                     "ui--selection-bar-other-value": t("ui.selection_bar.count.other", default: "%{count} selected") }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  # A checkbox the bar counts: `:item` for each thing to choose, `:all` for
  # one that chooses them all. `form:` is the id of the form it posts with;
  # `class:` restyles it, such as a round box over a photo.
  def self.checkbox(kind, label:, name: nil, value: nil, form: nil, checked: false, **options)
    attrs = { "aria-label": label, data: { selection: kind }, checked: checked, **options }
    attrs["form"] = form if form # the HTML attribute; `form:` is a form builder to Checkbox
    UI::Checkbox.new(name: name, value: value, unchecked_value: nil, **attrs)
  end

  def clear_attrs
    { variant: :ghost, size: :icon, class: "shrink-0 rounded-full",
      aria: { label: t("ui.selection_bar.clear", default: "Clear selection") },
      data: { action: "ui--selection-bar#clear" } }
  end
end

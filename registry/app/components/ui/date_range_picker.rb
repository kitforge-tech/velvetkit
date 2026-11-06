# frozen_string_literal: true

require "securerandom"

# Two dates, from and to, for report filters: sales this month, stock moves
# last week. Typed like UI::DatePicker, in the locale's format, or picked on a
# calendar showing two months (one on a phone), or chosen from presets such as
# "Last 7 days" and "This month".
#
#   <%= form_with url: reports_path, method: :get, data: { controller: "autosubmit" } do %>
#     <%= render(UI::DateRangePicker.new(label: "Period", from: params[:from], to: params[:to])) %>
#   <% end %>
#
# It submits `from` and `to` as ISO dates (`from_name:` and `to_name:` change
# them), or with a form builder, `from_field:` and `to_field:`. Choosing a
# range on the calendar or from a preset fires `change` on the field, so a
# filter form can submit itself; typing doesn't, until the form is sent.
#
# Presets are worked out on the server, from `Date.current`, so "today" is the
# app's today. `presets: false` leaves them out, and an array of
# `[label, from, to]` replaces them. A To before the From is marked invalid
# and not submitted.
class UI::DateRangePicker < UI::Base
  def initialize(from: nil, to: nil, from_name: "from", to_name: "to", form: nil, from_field: nil, to_field: nil,
                 label: nil, presets: true, min: nil, max: nil, hint: true, required: false, error: nil,
                 disabled: false, class: nil, **html_attrs)
    @from       = from
    @to         = to
    @from_name  = from_name
    @to_name    = to_name
    @form       = form
    @from_field = from_field
    @to_field   = to_field
    @label      = label
    @presets    = presets
    @min        = min
    @max        = max
    @hint       = hint
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @wrapper    = UI::FormField.new(label: false, error: error, form: form, field: from_field, for: from_id)
  end

  attr_reader :wrapper, :label

  def uid = @uid ||= SecureRandom.hex(4)
  def from_id = "ui-date-range-#{uid}-from"
  def to_id = "ui-date-range-#{uid}-to"
  def panel_id = "ui-date-range-#{uid}-panel"
  def hint_id = "ui-date-range-#{uid}-hint"

  def bound? = @form.present? && @from_field.present? && @to_field.present?
  def from_name = bound? ? "#{@form.object_name}[#{@from_field}]" : @from_name
  def to_name = bound? ? "#{@form.object_name}[#{@to_field}]" : @to_name
  def from_iso = UI::DatePicker.iso(bound_value(@from_field) || @from)
  def to_iso = UI::DatePicker.iso(bound_value(@to_field) || @to)
  def from_typed = UI::DatePicker.typed(from_iso)
  def to_typed = UI::DatePicker.typed(to_iso)
  def placeholder = UI::DatePicker.placeholder

  def render_label? = @label.present?
  def render_hint? = @hint != false
  def disabled? = @disabled
  def required? = @required

  def describedby
    [ (hint_id if render_hint?), (wrapper.error_id if wrapper.error_message) ].compact.join(" ").presence
  end

  def root_attrs
    attrs = @html_attrs.except(:data)
    attrs[:class] = cn("relative w-full", @user_class)
    attrs[:data] = { controller: "ui--date-range-picker",
                     "ui--date-range-picker-module-url-value": helpers.asset_path("cally.js"),
                     "ui--date-range-picker-order-value": UI::DatePicker.part_order,
                     "ui--date-range-picker-separator-value": UI::DatePicker.separator,
                     action: "click@window->ui--date-range-picker#closeOnOutsideClick " \
                             "keydown@window->ui--date-range-picker#closeOnEscape" }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  # The two typed fields share one border, which lights up while either has focus.
  def group_classes
    cn("flex h-9 w-full items-center rounded-md border border-input bg-background text-sm text-foreground",
       "transition-all ring-offset-background has-[input:focus]:ring-2 has-[input:focus]:ring-primary has-[input:focus]:ring-offset-1",
       "has-[[aria-invalid=true]]:border-destructive",
       { "border-destructive" => wrapper.error?, "cursor-not-allowed opacity-50" => disabled? })
  end

  def input_attrs(which)
    { type: "text", id: which == :from ? from_id : to_id, inputmode: "numeric", autocomplete: "off",
      placeholder: placeholder, value: which == :from ? from_typed : to_typed,
      required: required?, disabled: disabled?,
      class: "h-full w-full min-w-0 bg-transparent px-3 text-center outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed",
      aria: { label: t("ui.date_range_picker.#{which}", default: which == :from ? "Start date" : "End date"),
              describedby: describedby, invalid: ("true" if wrapper.error?) },
      data: { "ui--date-range-picker-target": which.to_s, action: "input->ui--date-range-picker#typed" } }
  end

  # [label, from, to], as ISO dates.
  def preset_list
    list = @presets == true ? default_presets : Array(@presets.presence)
    list.map { |label, from, to| [ label, UI::DatePicker.iso(from), UI::DatePicker.iso(to) ] }
  end

  def calendar_attrs
    { months: 2, min: UI::DatePicker.iso(@min), max: UI::DatePicker.iso(@max), "first-day-of-week": 1,
      locale: I18n.locale == :en ? "en-IN" : I18n.locale.to_s,
      data: { "ui--date-range-picker-target": "calendar", action: "change->ui--date-range-picker#picked" } }
  end

  private

  def bound_value(field)
    return nil unless bound? && @form.object.respond_to?(field)

    @form.object.public_send(field)
  end

  def default_presets
    today = Date.current
    [ [ preset(:today, "Today"), today, today ],
      [ preset(:yesterday, "Yesterday"), today - 1, today - 1 ],
      [ preset(:last_7_days, "Last 7 days"), today - 6, today ],
      [ preset(:last_30_days, "Last 30 days"), today - 29, today ],
      [ preset(:this_month, "This month"), today.beginning_of_month, today ],
      [ preset(:last_month, "Last month"), today.prev_month.beginning_of_month, today.prev_month.end_of_month ],
      [ preset(:this_year, "This year"), today.beginning_of_year, today ] ]
  end

  def preset(key, default) = t("ui.date_range_picker.presets.#{key}", default: default)
end

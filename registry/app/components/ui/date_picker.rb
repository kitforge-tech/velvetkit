# frozen_string_literal: true

require "securerandom"

# UI::DatePicker — a typed date with a calendar under it, or a range of two.
#
#   <%= render(UI::DatePicker.new(form: f, field: :starts_on, required: true)) %>
#   <%= render(UI::DatePicker.new(name: "event[date]", value: @date, label: "Date")) %>
#   <%= render(UI::DatePicker.new(range: true, label: "Period", from: params[:from], to: params[:to])) %>
#   <%= render(UI::DatePicker.new(range: true, form: f, from_field: :starts_on, to_field: :ends_on)) %>
#
# People who know a date type it; the rest pick it. The field takes digits
# only and puts the separators in as you go, in the locale's order
# (`date.formats.typed`, DD/MM/YYYY in English), and the form gets an ISO date
# in a hidden field, so a date typed for a British office isn't read the
# American way. Clicking or tabbing into the field opens the calendar, whose
# month and year headings jump to a month or a year.
#
# `range: true` is two dates, From and To, for report filters: typed, picked
# on a calendar of two months (one on a phone), or chosen from presets such as
# "Last 7 days", worked out from `Date.current`. `presets: false` leaves those
# out; an array of `[label, from, to]` replaces them. Choosing a range, a date
# or a preset, or clearing it, fires `change` on the field, so a filter form
# can send itself.
#
# The calendar is Vanilla Calendar Pro, loaded with its stylesheet the first
# time a calendar opens, so a page nobody opens one on downloads neither.
class UI::DatePicker < UI::Base
  def initialize(name: nil, value: nil, form: nil, field: nil, label: nil,
                 range: false, from: nil, to: nil, from_name: "from", to_name: "to", from_field: nil, to_field: nil,
                 presets: true, required: false, error: nil, disabled: false, hint: true,
                 min: nil, max: nil, class: nil, **html_attrs)
    @name       = name
    @value      = value
    @form       = form
    @field      = field
    @label      = label
    @range      = range
    @from       = from
    @to         = to
    @from_name  = from_name
    @to_name    = to_name
    @from_field = from_field
    @to_field   = to_field
    @presets    = presets
    @required   = required
    # The hint teaches the format, which a form field wants and a filter
    # toolbar does not: there the value is already on screen in that format.
    @hint       = hint
    @error      = error
    @disabled   = disabled
    @min        = min
    @max        = max
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    # Only for the error: the label and the format hint are laid out here.
    @wrapper    = UI::FormField.new(label: false, error: error, form: form, field: range ? from_field : field, for: input_id)
  end

  attr_reader :wrapper

  def range? = @range
  def required? = @required
  def disabled? = @disabled

  # ── The written format ────────────────────────────────────────────────────

  # The one string everything else is derived from.
  def self.date_format = I18n.t("date.formats.typed")

  # "%d/%m/%Y" -> "DD/MM/YYYY": the placeholder and the hint, so what people
  # are told matches what the field accepts by construction.
  def self.placeholder
    date_format.gsub("%d", "DD").gsub("%m", "MM").gsub("%Y", "YYYY").gsub("%y", "YY")
  end

  # "%d/%m/%Y" -> "DMY", for the controller's mask and parser.
  def self.part_order = date_format.scan(/%([dmyY])/).flatten.map(&:upcase).join

  def self.separator = date_format[/[^%a-zA-Z]/] || "/"

  # A Date or ISO string in the locale's written format, so the field is right
  # before any JavaScript has run.
  def self.typed(value)
    return nil if value.blank?

    date = value.respond_to?(:strftime) ? value : Date.parse(value.to_s)
    I18n.l(date, format: :typed)
  rescue Date::Error
    value
  end

  def self.iso(value)
    value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.presence
  end

  def placeholder = self.class.placeholder

  # ── Fields ────────────────────────────────────────────────────────────────

  def input_id = @input_id ||= "ui-date-#{SecureRandom.hex(4)}"
  def to_id = "#{input_id}-to"
  def panel_id = "#{input_id}-panel"
  def hint_id = "#{input_id}-hint"

  # What each typed field submits through: [target, hidden name, ISO value].
  def fields
    if range?
      [ [ :from, hidden_name(@from_field, @from_name), self.class.iso(bound(@from_field) || @from) ],
        [ :to, hidden_name(@to_field, @to_name), self.class.iso(bound(@to_field) || @to) ] ]
    else
      [ [ :input, hidden_name(@field, @name), self.class.iso(bound(@field) || @value) ] ]
    end
  end

  def value? = fields.any? { |_, _, iso| iso.present? }

  def label_text
    return @label if @label.present?
    return nil unless @form && (@field || @from_field)

    @form.object.class.try(:human_attribute_name, @field || @from_field) || (@field || @from_field).to_s.humanize
  end

  def render_label? = @label != false && label_text.present?
  def render_hint? = @hint != false

  def hint_text
    key = range? ? "hint_range" : "hint"
    default = range? ? "Type the dates as %{pattern}, or pick them" : "Type the date as %{pattern}, or use the calendar"
    t("ui.date_picker.#{key}", pattern: placeholder, default: default)
  end

  def describedby
    [ (hint_id if render_hint?), (wrapper.error_id if wrapper.error_message) ].compact.join(" ").presence
  end

  def input_attrs(target, iso)
    from = target == :to ? false : true
    { type: "text", id: from ? input_id : to_id, inputmode: "numeric", autocomplete: "off",
      placeholder: placeholder, value: self.class.typed(iso), maxlength: placeholder.length,
      required: required?, disabled: disabled?, size: placeholder.length,
      class: input_classes,
      aria: { label: (t("ui.date_picker.#{target}", default: target == :from ? "Start date" : "End date") if range?),
              describedby: describedby, invalid: ("true" if wrapper.error?) },
      data: { "ui--date-picker-target": "field", action: "input->ui--date-picker#typed focus->ui--date-picker#open " \
                                                         "click->ui--date-picker#open keydown->ui--date-picker#keydown" } }
  end

  # Sized to the date rather than stretched, so a range reads "01/09/2026 – 30/09/2026".
  def input_classes
    cn("h-full min-w-0 bg-transparent px-3 tabular-nums outline-none placeholder:text-muted-foreground",
       "disabled:cursor-not-allowed", range? ? "w-[calc(10ch+1.75rem)]" : "w-full")
  end

  # The typed fields share one border, lit while either has focus.
  def group_classes
    cn("flex h-9 w-full items-center rounded-md border border-input bg-background text-sm text-foreground",
       "transition-all ring-offset-background has-[input:focus]:ring-2 has-[input:focus]:ring-primary has-[input:focus]:ring-offset-1",
       "has-[[aria-invalid=true]]:border-destructive",
       { "border-destructive" => wrapper.error?, "cursor-not-allowed opacity-50" => disabled? })
  end

  def root_attrs
    attrs = @html_attrs.except(:data)
    attrs[:class] = cn("relative w-full", @user_class)
    attrs[:data] = { controller: "ui--date-picker",
                     # Propshaft digests the filenames, so the URLs come from Ruby.
                     "ui--date-picker-module-url-value": helpers.asset_path("vanilla_calendar.js"),
                     "ui--date-picker-style-url-value": helpers.asset_path("vanilla_calendar.css"),
                     "ui--date-picker-order-value": self.class.part_order,
                     "ui--date-picker-separator-value": self.class.separator,
                     "ui--date-picker-range-value": range?,
                     "ui--date-picker-min-value": self.class.iso(@min),
                     "ui--date-picker-max-value": self.class.iso(@max),
                     "ui--date-picker-locale-value": I18n.locale == :en ? "en-IN" : I18n.locale.to_s,
                     "ui--date-picker-labels-value": labels.to_json,
                     action: "click@window->ui--date-picker#closeOnOutsideClick keydown@window->ui--date-picker#closeOnEscape " \
                             "focusout->ui--date-picker#leave" }
                   .merge(@html_attrs[:data] || {}).compact
    attrs
  end

  # Words the calendar shows or says, from the locale.
  def labels
    { pickEnd: t("ui.date_picker.pick_end", default: "Now pick an end date"),
      previous: t("ui.date_picker.previous", default: "Previous month"),
      next: t("ui.date_picker.next", default: "Next month"),
      days: t("ui.date_picker.days", default: "%{count} days") }
  end

  # ── Presets ───────────────────────────────────────────────────────────────

  # [label, from, to], as ISO dates. Only for a range.
  def preset_list
    return [] unless range?

    list = @presets == true ? default_presets : Array(@presets.presence)
    list.map { |name, from, to| [ name, self.class.iso(from), self.class.iso(to) ] }
  end

  def preset_pressed?(from, to) = fields.map(&:last) == [ from, to ]

  private

  def hidden_name(field, name)
    return "#{@form.object_name}[#{field}]" if @form && field

    name
  end

  def bound(field)
    return nil unless @form && field && @form.object.respond_to?(field)

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

  def preset(key, default) = t("ui.date_picker.presets.#{key}", default: default)
end

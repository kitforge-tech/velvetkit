# frozen_string_literal: true

# UI::DatePicker — a typed date field with a calendar beside it.
#
# Three inputs in one: what the user types (DD/MM/YYYY), what the form submits
# (ISO, hidden), and the calendar. The typed field comes first because people
# who know the date type it in a second: reaching a date years away in a
# calendar means clicking back month after month.
#
# The written format is not decided here. It comes from `date.formats.typed`
# in the locale, and this component derives the placeholder, the parse order
# and the separator from that one string — so a locale that writes dates
# differently changes what the field accepts, what it shows and what the hint
# says, together, with nothing hardcoded.
#
# The shipped English format is day-first; change `date.formats.typed` for
# month-first. A native date input follows the browser's locale instead, which
# is how the same form reads MM/DD on one machine and DD/MM on another, and how
# the 2nd of May gets recorded as the 5th of February.
#
# Cally is ~9 KB gzipped and loaded only when the calendar is first opened, so
# a form nobody opens a calendar on downloads nothing.
#
# Usage:
#   <%= render(UI::DatePicker.new(form: f, field: :starts_on, required: true)) %>
#   <%= render(UI::DatePicker.new(name: "event[date]", value: @date, label: "Date")) %>
class UI::DatePicker < UI::Base
  def initialize(name: nil, value: nil, form: nil, field: nil, label: nil,
                 required: false, error: false, disabled: false, hint: true,
                 min: nil, max: nil, class: nil, **html_attrs)
    @name = name
    @value = value
    @form = form
    @field = field
    @label = label
    @required = required
    # The hint teaches the format, which a form field wants and a filter
    # toolbar does not — there the value is already on
    # screen in the format the hint would describe.
    @hint = hint
    @error = error
    @disabled = disabled
    @min = min
    @max = max
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def field_name = @name || (@form && @field && "#{@form.object_name}[#{@field}]")

  # The value the form submits, always ISO, whatever was typed.
  def iso_value
    raw = @value || (@form && @field && @form.object&.public_send(@field))
    raw.respond_to?(:strftime) ? raw.strftime("%Y-%m-%d") : raw.presence
  end

  def label_text
    return @label if @label.present?
    return nil unless @form && @field

    @form.object.class.try(:human_attribute_name, @field) || @field.to_s.humanize
  end

  def render_label? = @label != false && label_text.present?
  def render_hint? = @hint != false

  def input_id = @input_id ||= "ui-date-#{SecureRandom.hex(4)}"
  def panel_id = "#{input_id}-panel"

  def classes = cn("relative", @user_class)

  def input_classes
    cn(
      "flex w-full rounded-md border border-input bg-background text-foreground",
      "placeholder:text-muted-foreground transition-all focus:outline-none",
      "focus:ring-2 focus:ring-primary focus:ring-offset-1 ring-offset-background",
      "disabled:cursor-not-allowed disabled:opacity-50 h-9 pl-3 pr-10 py-2 text-sm",
      # aria-invalid rather than a Ruby flag, so a date the user mistypes is
      # marked without a round trip.
      "aria-invalid:border-destructive aria-invalid:ring-destructive",
      @error && "border-destructive"
    )
  end

  # The one string everything else here is derived from.
  def date_format = I18n.t("date.formats.typed")

  # "%d/%m/%Y" -> "DD/MM/YYYY". Shown as the placeholder and in the hint, so
  # what the user is told matches what the parser accepts by construction.
  def placeholder
    date_format.gsub("%d", "DD").gsub("%m", "MM").gsub("%Y", "YYYY").gsub("%y", "YY")
  end

  # "%d/%m/%Y" -> "DMY". The controller builds its parser from this rather
  # than assuming an order.
  def part_order = date_format.scan(/%([dmyY])/).flatten.map(&:upcase).join

  def separator = date_format[/[^%a-zA-Z]/] || "/"

  # Rendered server-side in the locale's format, so the field is already right
  # before any JavaScript has loaded.
  def typed_value
    iso = iso_value
    return nil if iso.blank?

    date = iso.respond_to?(:strftime) ? iso : Date.parse(iso.to_s)
    I18n.l(date, format: :typed)
  rescue Date::Error
    iso
  end
end

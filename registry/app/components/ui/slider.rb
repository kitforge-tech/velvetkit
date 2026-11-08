# frozen_string_literal: true

require "securerandom"

# A handle to drag along a track: volume, a zoom level, how often to be
# emailed. `range: true` gives it two, a low and a high, for filters like a
# price band or opening hours.
#
#   <%= render(UI::Slider.new(name: "volume", value: 40, label: "Volume", value_text: "%{value}%", show_value: true)) %>
#   <%= render(UI::Slider.new(form: f, field: :alert_at, min: 50, max: 100, step: 5)) %>
#   <%= render(UI::Slider.new(range: true, label: "Price", min: 0, max: 500, step: 10,
#                             from: params[:min_price] || 0, to: params[:max_price] || 500,
#                             from_name: "min_price", to_name: "max_price", value_text: "$%{value}", show_value: true)) %>
#   <%= render(UI::Slider.new(range: true, form: f, from_field: :opens_at, to_field: :closes_at, max: 24)) %>
#
# Each handle is the browser's own <input type="range">, so it submits with
# the form, the arrow keys, Page Up and Down, Home and End move it, and screen
# readers announce it as a slider. Pressing anywhere on the track moves the
# nearest handle there and drags it. The two handles of a range can meet but
# not pass each other.
#
# `value_text:` formats a value for the reader to see (with
# `show_value: true`) and for a screen reader to hear: "%{value}%",
# "$%{value}", "%{value}:00". A range shows both, as "$20 – $80".
#
# `marks:` labels points along the track: an array of values, or a hash of
# value => label. A labelled value is also what's shown and heard there, so
#
#   <%= render(UI::Slider.new(name: "quality", min: 1, max: 3, value: 2, show_value: true, label: "Quality",
#                             marks: { 1 => "Low", 2 => "Medium", 3 => "High" })) %>
#
# says "Medium" rather than 2. Pressing a mark moves the nearest handle to it.
#
# `aria:` goes on the input, or on a range's group: with `label: false`, give
# it `aria: { label: "Volume" }` so it still has a name.
#
# It fires the inputs' own `input` while a handle moves and `change` when it's
# let go, so a filter form can submit on change. Setting a handle's value from
# JavaScript, dispatch `input` on it after, and the track follows.
class UI::Slider < UI::Base
  SIZES = {
    sm:      { thumb: "1.375rem", thumb_height: "1rem", track: "h-1.5" },
    default: { thumb: "1.75rem", thumb_height: "1.25rem", track: "h-2.5" },
    lg:      { thumb: "2.25rem", thumb_height: "1.625rem", track: "h-3.5" }
  }.freeze

  # The thumb is drawn by the browser, styled the same for WebKit and Firefox,
  # with every class written out in full so Tailwind finds it: a white pill,
  # --thumb wide and --thumb-h tall, lifted by a shadow rather than outlined. The input sits over the track, as
  # tall as the thumb, so the thumb is centred on it with no offsets. Pointer events go to the track (see the controller); the input
  # still takes focus and the keyboard.
  INPUT = [
    "pointer-events-none absolute inset-0 m-0 h-(--thumb-h) w-full appearance-none bg-transparent outline-none",
    "[&::-webkit-slider-runnable-track]:h-full [&::-webkit-slider-runnable-track]:bg-transparent",
    "[&::-moz-range-track]:bg-transparent",
    "[&::-webkit-slider-thumb]:h-(--thumb-h) [&::-webkit-slider-thumb]:w-(--thumb) " \
    "[&::-webkit-slider-thumb]:box-border [&::-webkit-slider-thumb]:appearance-none " \
    "[&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:border-3 " \
    "[&::-webkit-slider-thumb]:border-transparent [&::-webkit-slider-thumb]:bg-white " \
    "[&::-webkit-slider-thumb]:shadow-[0_1px_3px_rgb(0_0_0/0.3),0_0_0_0.5px_rgb(0_0_0/0.08)] " \
    "[&::-webkit-slider-thumb]:transition-[border-color,box-shadow,scale] [&::-webkit-slider-thumb]:duration-150 " \
    "motion-reduce:[&::-webkit-slider-thumb]:transition-none",
    "[&::-moz-range-thumb]:h-(--thumb-h) [&::-moz-range-thumb]:w-(--thumb) " \
    "[&::-moz-range-thumb]:box-border [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:border-3 " \
    "[&::-moz-range-thumb]:border-transparent [&::-moz-range-thumb]:bg-white " \
    "[&::-moz-range-thumb]:shadow-[0_1px_3px_rgb(0_0_0/0.3),0_0_0_0.5px_rgb(0_0_0/0.08)] " \
    "[&::-moz-range-thumb]:transition-[border-color,box-shadow,scale] [&::-moz-range-thumb]:duration-150 " \
    "motion-reduce:[&::-moz-range-thumb]:transition-none",
    "focus-visible:[&::-webkit-slider-thumb]:ring-3 focus-visible:[&::-webkit-slider-thumb]:ring-ring/40",
    "focus-visible:[&::-moz-range-thumb]:ring-3 focus-visible:[&::-moz-range-thumb]:ring-ring/40",
    # While dragged: a thick, faint ring in place of the shadow.
    "data-active:[&::-webkit-slider-thumb]:border-foreground/15 data-active:[&::-moz-range-thumb]:border-foreground/15",
    "data-active:[&::-webkit-slider-thumb]:shadow-none data-active:[&::-moz-range-thumb]:shadow-none"
  ].join(" ").freeze

  # The ends sit flush with the track's ends; the rest centre on their value.
  MARK_PLACES = { 0.0 => { shift: "", style: "inset-inline-start: 0px" },
                  1.0 => { shift: "-translate-x-full rtl:translate-x-full", style: "inset-inline-start: 100%" } }.freeze

  # Where a value sits along the track: the thumb's centre goes from half a
  # thumb in at one end to half a thumb in at the other.
  def self.at(fraction) = "calc(var(--thumb) / 2 + (100% - var(--thumb)) * #{fraction})"

  def initialize(name: nil, value: nil, min: 0, max: 100, step: 1, form: nil, field: nil,
                 range: false, from: nil, to: nil, from_name: "from", to_name: "to", from_field: nil, to_field: nil,
                 label: nil, hint: nil, error: nil, value_text: nil, show_value: false, marks: nil,
                 size: :default, disabled: false, class: nil, **html_attrs)
    @min        = min.to_f
    @max        = [ max.to_f, @min ].max
    @step       = step.to_f.positive? ? step.to_f : 1.0
    @form       = form
    @range      = range
    @label      = label
    @value_text = value_text
    @show_value = show_value
    @marks      = marks.is_a?(Hash) ? marks.transform_keys(&:to_f) : Array(marks).to_h { |m| [ m.to_f, nil ] }
    @size       = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @aria       = html_attrs.delete(:aria) || {}
    @html_attrs = html_attrs
    @id         = html_attrs.delete(:id) || "ui-slider-#{SecureRandom.hex(4)}"
    @fields     = handles(name: name, value: value, field: field, from: from, to: to, from_name: from_name,
                          to_name: to_name, from_field: from_field, to_field: to_field)
    @wrapper    = UI::FormField.new(label: false, hint: hint, error: error, form: form,
                                    field: range ? from_field : field, for: @id)
  end

  attr_reader :wrapper, :fields

  def range? = @range
  def disabled? = @disabled
  def show_value? = @show_value

  def label_id = "#{@id}-label"

  def label_text
    return nil if @label == false
    return @label if @label.present?

    field = @fields.first[:field]
    return nil unless @form && field

    @form.object.class.try(:human_attribute_name, field) || field.to_s.humanize
  end

  def root_attrs
    { **@html_attrs, class: cn("w-full space-y-2", disabled? && "opacity-50", @user_class),
      role: ("group" if range?), aria: ({ labelledby: (label_id if label_text), **@aria }.compact if range?),
      style: "--thumb: #{SIZES[@size][:thumb]}; --thumb-h: #{SIZES[@size][:thumb_height]}; --from: #{number(fraction(lower))}; --to: #{number(fraction(upper))}",
      data: { slot: "slider", controller: "ui--slider", "ui--slider-format-value": text_format,
              "ui--slider-range-format-value": range_format, "ui--slider-labels-value": labels.to_json,
              **(@html_attrs[:data] || {}) } }.compact
  end

  # Grows from the start of the track to the value, or between a range's two.
  def fill_style
    start = range? ? self.class.at("var(--from)") : "0px"
    width = range? ? "calc((100% - var(--thumb)) * (var(--to) - var(--from)))" : self.class.at("var(--to)")
    "inset-inline-start: #{start}; width: #{width}"
  end

  def track_attrs
    { class: cn("relative h-(--thumb-h) touch-pan-y select-none", disabled? ? "cursor-not-allowed" : "cursor-pointer"),
      data: { "ui--slider-target": "track",
              action: ("pointerdown->ui--slider#press" unless disabled?) } }.compact
  end

  def track_class = cn("absolute inset-x-0 top-1/2 -translate-y-1/2 overflow-hidden rounded-full bg-foreground/10",
                       SIZES[@size][:track])

  def input_attrs(handle)
    { type: "range", id: handle[:id], min: number(@min), max: number(@max), step: number(@step),
      value: number(handle[:value]), disabled: (true if disabled?), class: INPUT,
      "aria-valuetext": value_text(handle[:value]), "aria-label": handle_name(handle),
      "aria-describedby": wrapper.describedby, "aria-invalid": ("true" if wrapper.error?),
      data: { "ui--slider-target": "input", action: "input->ui--slider#sync" },
      aria: (@aria unless range?) }.compact
  end

  # Renders the bound field through the form builder, so it takes the model's
  # name, id prefix and value the way a Rails form expects.
  def render_input(handle)
    attrs = input_attrs(handle)
    if @form && handle[:field]
      @form.range_field(handle[:field], **attrs.except(:type, :value), value: attrs[:value])
    else
      tag.input(**attrs, name: handle[:name])
    end
  end

  def output_text = range? ? range_text(lower, upper) : value_text(upper)

  def header? = label_text.present? || show_value?

  def marks? = @marks.any?

  # Each mark's label and where it sits.
  def marks
    @marks.filter_map do |value, label|
      next unless value.between?(@min, @max)

      at = fraction(value)
      { label: label.presence || format_value(value), value: number(value), **MARK_PLACES.fetch(at.to_f) { centred(at) } }
    end
  end

  def centred(at) = { shift: "-translate-x-1/2 rtl:translate-x-1/2", style: "inset-inline-start: #{self.class.at(at)}" }

  def mark_attrs(mark)
    { class: cn("absolute top-0 whitespace-nowrap", mark[:shift], !disabled? && "cursor-pointer hover:text-foreground"),
      style: mark[:style],
      data: { action: ("click->ui--slider#pick" unless disabled?), "ui--slider-value-param": mark[:value] }.compact }
  end

  def value_text(value)
    labels[number(value)] || text_format.gsub("%{value}", format_value(value))
  end

  private

  def handles(name:, value:, field:, from:, to:, from_name:, to_name:, from_field:, to_field:)
    if @range
      low  = snap(clamp(bound(from_field) || from || @min))
      high = snap(clamp(bound(to_field) || to || @max))
      low, high = high, low if low > high
      [ { id: @id, name: from_name, field: from_field, value: low, aria_label: :from },
        { id: "#{@id}-to", name: to_name, field: to_field, value: high,
          aria_label: :to } ]
    else
      # With no value, the middle, as the browser would.
      start = bound(field) || value || (@min + ((@max - @min) / 2))
      [ { id: @id, name: name, field: field, value: snap(clamp(start)), aria_label: nil } ]
    end
  end

  # A range's handles are named for screen readers; a single one has the label.
  def handle_name(handle)
    return nil unless handle[:aria_label]

    t("ui.slider.#{handle[:aria_label]}", default: handle[:aria_label] == :from ? "Minimum" : "Maximum")
  end

  def lower = range? ? @fields.first[:value] : @min
  def upper = @fields.last[:value]

  def bound(field)
    return nil unless @form && field && @form.object.respond_to?(field)

    @form.object.public_send(field).presence
  end

  def clamp(value) = value.to_f.clamp(@min, @max)

  # To the nearest step from min, the way the browser rounds a range input.
  def snap(value) = (@min + (((value - @min) / @step).round * @step)).clamp(@min, @max).round(decimals)

  def fraction(value)
    return 0 if @max == @min

    ((value - @min) / (@max - @min)).round(4)
  end

  def text_format = @value_text || "%{value}"

  def range_format = t("ui.slider.range_text", default: "%{from} – %{to}")

  def range_text(low, high) = range_format.gsub("%{from}", value_text(low)).gsub("%{to}", value_text(high))

  def labels = @marks.each_with_object({}) { |(value, label), all| all[number(value)] = label if label.present? }

  def format_value(value) = number(value.to_f.round(decimals))

  def decimals = number(@step)[/\.(\d+)\z/, 1].to_s.length

  # 3, not 3.0; 2.5 stays 2.5.
  def number(n) = (n.to_f % 1).zero? ? n.to_i.to_s : n.to_f.to_s
end

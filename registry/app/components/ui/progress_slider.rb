# frozen_string_literal: true

require "securerandom"

# A thick bar to drag for one value, made to feel pressed: it squeezes thinner
# while it's held and springs back when let go, a bubble over the handle shows
# the value and leans with how fast it's dragged, and the value under the bar
# rolls over to the next one. For a setting someone plays with, like a
# reasoning effort, a playback position or a brightness; UI::Slider is the
# quieter one for forms.
#
#   <%= render(UI::ProgressSlider.new(name: "brightness", value: 60, label: "Brightness", value_text: "%{value}%")) %>
#   <%= render(UI::ProgressSlider.new(name: "effort", min: 0, max: 4, value: 1, label: "Reasoning effort",
#                                     marks: { 0 => "Low", 1 => "Medium", 2 => "High", 3 => "Extra high",
#                                               4 => "Max" })) %>
#   <%= render(UI::ProgressSlider.new(form: f, field: :volume, step: 5)) %>
#
# It's the browser's own <input type="range"> underneath, so it submits with
# the form, the arrow keys, Page Up and Down, Home and End move it, and screen
# readers announce it as a slider. Pressing anywhere on the bar jumps there and
# drags. Dragged past an end, the bar stretches after the pointer, thinning as
# it does, and let go it springs back with a shiver.
#
# `value_text:` formats the value in the bubble and the caption, and for a
# screen reader: "%{value}%", "$%{value}". `marks:` is a hash of value =>
# label, said in their place ("Medium" rather than 1). `show_value: false`
# leaves out the caption under the bar; `bubble: false` the bubble. With no
# label, leave room above the bar for the bubble to pop up into.
#
# `fill:` is the filled part's colour, shaded darker to lighter along it.
# `:fade`, the default, is grey until the value reaches the top, then fades
# into the brand colour: a bar that's full looks it. `:brand` is the brand
# colour all the way.
#
# `ticks:` draws a line at each step, by default when there are no more than
# 24 of them; `true` or `false` to choose. Even with `true` there are no more
# than 100: past that they'd run together.
#
# With reduced motion it neither squeezes, leans nor rolls. It fires the
# input's own `input` while it moves and `change` when it's let go.
#
# On a touch screen a finger has to move sideways before it drags, so a page
# can still be scrolled with a swipe that starts on the bar; a tap jumps to
# where it lands. The bar takes touches a little above and below itself, to
# make a big enough target.
class UI::ProgressSlider < UI::Base
  SIZES = { sm: "h-6", default: "h-8", lg: "h-10" }.freeze

  MAX_AUTO_TICKS = 24
  MAX_TICKS = 100

  # The input is there for the keyboard, the form and screen readers, and
  # can't be seen. Pointer events go to the track (see the controller).
  INPUT = "peer absolute inset-0 m-0 size-full cursor-[inherit] opacity-0 pointer-events-none"

  # Squeezes on press, quickly; let go, it springs back on a damped spring
  # (the linear() curve), overshooting and settling, so a bar that was
  # stretched past an end shivers back. Each state's transition is the one used
  # on the way into it. Stretched by --stretch, it thins as well, 2.5 times as
  # much, the way something elastic would. The curve stays on one line:
  # Tailwind finds the class by reading this file, and can't across a break.
  BAR = "relative size-full overflow-hidden rounded-lg bg-foreground/10 origin-(--stretch-origin) " \
        "[transform:scale(var(--stretch,1),1)] transition-transform duration-650 " \
        "ease-[linear(0,0.078,0.262,0.49,0.712,0.9,1.037,1.121,1.158,1.16,1.138,1.103,1.066,1.032,1.005,0.987,0.977,0.973,0.975,0.98,0.986,0.992,0.997,1.001,1.003,1.004,1)] " \
        "group-hover/progress-slider:[transform:scale(var(--stretch,1),0.92)] " \
        "group-data-dragging/progress-slider:[transform:scale(var(--stretch,1),calc(0.6*(1-(var(--stretch,1)-1)*2.5)))] " \
        "group-data-dragging/progress-slider:duration-150 group-data-dragging/progress-slider:ease-out " \
        "peer-focus:ring-2 peer-focus:ring-primary peer-focus:ring-offset-1 ring-offset-background " \
        "motion-reduce:transform-none! motion-reduce:transition-none " \
        "forced-colors:border forced-colors:border-[CanvasText] " \
        "forced-colors:peer-focus:outline-2 forced-colors:peer-focus:outline-offset-2 forced-colors:peer-focus:outline-[Highlight]"

  # With forced colours (Windows' high contrast) backgrounds become the page's
  # and shadows go, so the bar is outlined, the fill is the system's highlight
  # with the handle in its text colour, and focus is an outline.
  FORCED_FILL = "forced-colors:forced-color-adjust-none forced-colors:bg-[Highlight]"
  FORCED_ON_FILL = "forced-colors:bg-[HighlightText] forced-colors:ring-0"

  # Grows from the start of the bar to the value; its shading spans just
  # what's filled, darker at the start.
  FILL = "absolute inset-y-0 start-0 w-[calc(var(--to)*100%)] overflow-hidden " \
         "transition-[width] duration-200 ease-out motion-reduce:transition-none " \
         "group-data-dragging/progress-slider:transition-none"

  SHADE = "absolute inset-0 bg-linear-to-r rtl:bg-linear-to-l forced-colors:hidden"
  GREY = "#{SHADE} from-foreground/30 to-foreground/15"
  BRAND = "#{SHADE} from-primary to-[color-mix(in_oklab,var(--color-primary),white_30%)] " \
          "shadow-[inset_0_1px_0_rgb(255_255_255/0.3)]"

  # :fade lays the brand shading over the grey and fades it in at the top.
  FILLS = {
    fade:  [ GREY, "#{BRAND} opacity-0 transition-opacity duration-300 group-data-at-max/progress-slider:opacity-100" ],
    brand: [ BRAND ]
  }.freeze

  # A short upright pill just inside the end of the fill: the handle. The
  # fill's edge cuts it off near the start.
  HANDLE = "absolute end-1 top-1/2 h-1/2 w-1 -translate-y-1/2 rounded-full bg-white shadow-sm ring-1 ring-black/15 " \
           "#{FORCED_ON_FILL}"

  # Pops out over the handle while it's pointed at, held, or focused from the
  # keyboard (a tap focuses it too, and on a phone nothing would then take the
  # bubble away again), and leans by --tilt, which the controller sets from
  # the drag's speed.
  #
  # It centres over the handle, but near an end it slides in to stay over the
  # bar rather than hang off the page. In translate, % is the bubble's own
  # width and cqw the track's (the track is its container).
  BUBBLE = "pointer-events-none absolute bottom-full mb-2 origin-bottom " \
           "translate-x-[clamp(calc(var(--to)*-100cqw),-50%,calc((1-var(--to))*100cqw-100%))] " \
           "rtl:translate-x-[clamp(calc(100%-(1-var(--to))*100cqw),50%,calc(var(--to)*100cqw))] " \
           "whitespace-nowrap rounded-md bg-foreground px-2 py-1 text-xs font-medium tabular-nums text-background " \
           "shadow-md opacity-0 [transform:scale(0.6)_rotate(var(--tilt,0deg))] " \
           "transition-[opacity,transform,translate,inset-inline-start] duration-200 ease-[cubic-bezier(0.34,1.56,0.64,1)] " \
           "group-hover/progress-slider:opacity-100 group-hover/progress-slider:[transform:scale(1)_rotate(var(--tilt,0deg))] " \
           "group-data-dragging/progress-slider:opacity-100 " \
           "group-data-dragging/progress-slider:[transform:scale(1)_rotate(var(--tilt,0deg))] " \
           "group-data-dragging/progress-slider:transition-[opacity,transform] " \
           "peer-focus-visible:opacity-100 peer-focus-visible:[transform:scale(1)_rotate(var(--tilt,0deg))] " \
           "motion-reduce:transition-opacity motion-reduce:[transform:none]! forced-colors:border forced-colors:border-[CanvasText]"

  def initialize(name: nil, value: nil, min: 0, max: 100, step: 1, form: nil, field: nil,
                 label: nil, hint: nil, error: nil, value_text: nil, show_value: true, bubble: true,
                 marks: nil, ticks: nil, fill: :fade, size: :default, disabled: false, class: nil, **html_attrs)
    @min        = min.to_f
    @max        = [ max.nil? ? 100.0 : max.to_f, @min ].max
    @step       = step.to_f.positive? ? step.to_f : 1.0
    @name       = name
    @form       = form
    @field      = field
    @label      = label
    @value_text = value_text
    @show_value = show_value
    @bubble     = bubble
    @marks      = marks.is_a?(Hash) ? marks.transform_keys(&:to_f) : Array(marks).to_h { |m| [ m.to_f, nil ] }
    @ticks      = ticks
    @size       = SIZES.key?(size.to_s.to_sym) ? size.to_sym : :default
    @fill       = FILLS.key?(fill.to_s.to_sym) ? fill.to_sym : :fade
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @aria       = html_attrs.delete(:aria) || {}
    @html_attrs = html_attrs
    @id         = html_attrs.delete(:id) || "ui-progress-slider-#{SecureRandom.hex(4)}"
    # With no value, the middle, as the browser would.
    @value      = snap(clamp(bound || value.presence || (@min + ((@max - @min) / 2))))
    @wrapper    = UI::FormField.new(label: false, hint: hint, error: error, form: form, field: field, for: @id)
  end

  attr_reader :wrapper

  def disabled? = @disabled
  def show_value? = @show_value
  def bubble? = @bubble

  def label_text
    return nil if @label == false
    return @label if @label.present?
    return nil unless @form && @field

    @form.object.class.try(:human_attribute_name, @field) || @field.to_s.humanize
  end

  # A `data: { controller: }` or `style:` of the caller's own goes alongside
  # the slider's, rather than in place of it.
  def root_attrs
    data = @html_attrs[:data] || {}
    { **@html_attrs, class: cn("group/progress-slider w-full space-y-2", disabled? && "opacity-50", @user_class),
      style: [ "--to: #{number(fraction(@value))}; --stretch-origin: center", @html_attrs[:style] ].compact.join("; "),
      data: { slot: "progress-slider", **data, controller: [ "ui--progress-slider", data[:controller] ].compact.join(" "),
              "at-max": ("" if at_max?),
              "ui--progress-slider-format-value": text_format, "ui--progress-slider-labels-value": labels.to_json }.compact }
  end

  # At the top of the range, where :fade turns to the brand colour.
  def at_max? = @max > @min && @value >= @max

  # The bubble pops up over the bar, so with a label above it there's room
  # kept for it, or it would cover the label.
  def track_attrs
    { class: cn("@container relative touch-pan-y select-none [-webkit-touch-callout:none]",
                "pointer-coarse:before:absolute pointer-coarse:before:inset-x-0 pointer-coarse:before:-inset-y-2.5",
                SIZES[@size], disabled? ? "cursor-not-allowed" : "cursor-grab",
                "group-data-dragging/progress-slider:cursor-grabbing", bubble? && label_text && "mt-8"),
      data: { "ui--progress-slider-target": "track",
              action: ("pointerdown->ui--progress-slider#press" unless disabled?) }.compact }
  end

  def input_attrs
    { type: "range", id: @id, min: number(@min), max: number(@max), step: number(@step), value: number(@value),
      disabled: (true if disabled?), class: INPUT, "aria-valuetext": value_text(@value),
      "aria-describedby": wrapper.describedby, "aria-invalid": ("true" if wrapper.error?),
      data: { "ui--progress-slider-target": "input", action: "input->ui--progress-slider#sync" },
      aria: @aria.presence }.compact
  end

  # Renders the bound field through the form builder, so it takes the model's
  # name, id prefix and value the way a Rails form expects.
  def render_input
    attrs = input_attrs
    if @form && @field
      @form.range_field(@field, **attrs.except(:type, :value), value: attrs[:value])
    else
      tag.input(**attrs, name: @name)
    end
  end

  def bar_class = BAR

  def fill_class = cn(FILL, FORCED_FILL)

  def shades = FILLS[@fill]

  def bubble_style = "inset-inline-start: calc(var(--to) * 100%)"

  # Where each tick falls, as a percentage: every step between the ends. A
  # step that doesn't divide the range leaves the last one short of max.
  def ticks
    count = (((@max - @min) / @step) + 1e-9).floor
    count -= 1 if (count * @step) >= (@max - @min) - 1e-9
    return [] if count < 1 || @ticks == false || count > (@ticks ? MAX_TICKS : MAX_AUTO_TICKS)

    (1..count).map { |i| number((i * @step * 100.0 / (@max - @min)).round(4)) }
  end

  def tick_style(at) = "inset-inline-start: #{at}%"

  def output_text = value_text(@value)

  def value_text(value)
    labels[number(value)] || text_format.gsub("%{value}", format_value(value))
  end

  private

  def bound
    return nil unless @form && @field && @form.object.respond_to?(@field)

    @form.object.public_send(@field).presence
  end

  # NaN can't be placed: it's the start, as an empty number field would be.
  def clamp(value)
    value = value.to_f
    value.nan? ? @min : value.clamp(@min, @max)
  end

  # To the nearest step from min, the way the browser rounds a range input.
  def snap(value) = (@min + (((value - @min) / @step).round * @step)).clamp(@min, @max).round(decimals)

  def fraction(value)
    return 0 if @max == @min

    ((value - @min) / (@max - @min)).round(4)
  end

  def text_format = @value_text || "%{value}"

  def labels = @marks.each_with_object({}) { |(value, label), all| all[number(value)] = label if label.present? }

  def format_value(value) = number(value.to_f.round(decimals))

  def decimals = number(@step)[/\.(\d+)\z/, 1].to_s.length

  # 3, not 3.0; 2.5 stays 2.5.
  def number(n) = (n.to_f % 1).zero? ? n.to_i.to_s : n.to_f.to_s
end

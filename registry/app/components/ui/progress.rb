# frozen_string_literal: true

require "securerandom"

# A bar showing how far along something is: an upload, an import, storage
# used, a profile half filled in. Leave out `value:` and it shows that work is
# going on without saying how much is left.
#
#   <%= render(UI::Progress.new(value: 64, label: "Uploading report.pdf", show_value: true)) %>
#   <%= render(UI::Progress.new(value: 3, max: 12, label: "Importing", value_text: "%{value} of %{max} files", show_value: true)) %>
#   <%= render(UI::Progress.new(label: "Preparing your export")) %>
#
# Split by category, it adds up its segments and shows a legend:
#
#   <%= render(UI::Progress.new(max: 15, label: "Storage", value_text: "%{value} GB of %{max} GB",
#                               segment_text: "%{value} GB", show_value: true)) do |progress| %>
#     <% progress.with_segment(value: 6.4, label: "Photos") %>
#     <% progress.with_segment(value: 3.1, label: "Mail") %>
#   <% end %>
#
# With `max:` the segments fill as far as their total and the rest of the track
# is what's left: free space, tasks to do. Leave `max:` out and they fill the
# bar as shares of a whole, like traffic by source:
#
#   <%= render(UI::Progress.new(label: "Visits by source")) do |progress| %>
#     <% progress.with_segment(value: 5_210, label: "Search") %>
#     <% progress.with_segment(value: 2_870, label: "Direct") %>
#   <% end %>
#
# Segments take the chart colours in order. The legend names them, since a
# colour alone doesn't say which is which; `legend: false` leaves it out when
# the page already says. `segment_text:` is each one's amount in the legend,
# with %{value} and %{percent} (its share of max). It defaults to the value
# against a max, and to the percentage for shares of a whole.
#
# `value_text:` is what's shown (with `show_value: true`) and what a screen
# reader hears. It can use %{value}, %{max} and %{percent}, and defaults to
# "40%". `tone:` colours the bar (:success, :warning, :destructive) for a bar
# that means something, like storage nearly full.
#
# Updating it: re-render it from a Turbo Stream (with `method: :morph` the bar
# slides to its new width), or from JavaScript set its
# `data-ui--progress-value-value` attribute, as an upload's progress event
# would. It fires `ui--progress:complete` when it reaches the end.
class UI::Progress < UI::Base
  SIZES = { sm: "h-1", default: "h-2", lg: "h-3" }.freeze

  TONES = {
    default:     { track: "bg-primary/15", bar: "bg-primary" },
    success:     { track: "bg-emerald-500/15", bar: "bg-emerald-500 dark:bg-emerald-600" },
    warning:     { track: "bg-amber-500/15", bar: "bg-amber-500 dark:bg-amber-600" },
    destructive: { track: "bg-destructive/15", bar: "bg-destructive" }
  }.freeze

  # Slides a short bar across, again and again. With reduced motion it's a
  # full, faint bar instead: still there, not moving.
  INDETERMINATE = "absolute inset-y-0 w-2/5 animate-[velvetkit-progress_1.4s_ease-in-out_infinite] " \
                  "motion-reduce:w-full motion-reduce:animate-none motion-reduce:opacity-50"
  DETERMINATE = "h-full transition-[width] duration-300 ease-out motion-reduce:transition-none"

  SWATCHES = { 1 => "bg-chart-1", 2 => "bg-chart-2", 3 => "bg-chart-3", 4 => "bg-chart-4", 5 => "bg-chart-5" }.freeze

  renders_many :segments, UI::Progress::Segment

  def initialize(value: nil, max: nil, label: nil, value_text: nil, show_value: false, size: :default,
                 tone: :default, legend: true, segment_text: nil, class: nil, **html_attrs)
    @given_max  = max if max.to_f.positive?
    @value      = value&.clamp(0, @given_max || 100)
    @legend     = legend
    @segment_text = segment_text
    @label      = label
    @value_text = value_text
    @show_value = show_value
    @size       = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @tone       = TONES.key?(tone.to_sym) ? tone.to_sym : :default
    @user_class = binding.local_variable_get(:class)
    @aria       = html_attrs.delete(:aria) || {}
    @html_attrs = html_attrs
    @label_id   = "ui-progress-#{SecureRandom.hex(4)}"
  end

  attr_reader :label, :label_id

  # 100 unless given; with segments and no max:, their total, so they fill the
  # bar as shares of a whole.
  def max
    return @given_max if @given_max

    total = segments.sum(&:value)
    whole? ? total : 100
  end

  # Segments with no max: shares of a whole, not parts of a limit.
  def whole? = @given_max.nil? && segmented? && segments.sum(&:value).positive?

  # With segments, their total; the bar's own value: is ignored.
  def value
    return @value unless segmented?

    segments.sum(&:value).clamp(0, max)
  end

  def segmented? = segments.any?

  def indeterminate? = value.nil?

  # Rounded down, so it never says 100% before it's done.
  def percent
    return nil if indeterminate?

    (value.to_f / max * 100).floor
  end

  def text_format = @value_text || t("ui.progress.value_text", default: "%{percent}%")

  def value_text
    return nil if indeterminate?

    text_format.gsub("%{value}", number(value)).gsub("%{max}", number(max)).gsub("%{percent}", percent.to_s)
  end

  def header? = @label.present? || (@show_value && !indeterminate?)

  def root_attrs
    { **@html_attrs, class: cn("w-full", (header? || legend?) && "space-y-1.5", @user_class),
      data: { slot: "progress", controller: "ui--progress", "ui--progress-max-value": number(max),
              "ui--progress-format-value": text_format,
              "ui--progress-determinate-class": DETERMINATE, "ui--progress-indeterminate-class": INDETERMINATE,
              **(@html_attrs[:data] || {}),
              **(indeterminate? ? {} : { "ui--progress-value-value": number(value) }) } }
  end

  def bar_attrs
    named = @label.present? ? { labelledby: label_id } : { label: t("ui.progress.label", default: "Progress") }
    { role: "progressbar", class: cn("relative w-full overflow-hidden rounded-full", SIZES[@size], TONES[@tone][:track]),
      data: { state: state, "ui--progress-target": "bar" },
      aria: { valuemin: 0, valuemax: number(max), valuenow: (number(value) unless indeterminate?),
              valuetext: value_text, busy: (true if state != "complete"), **named, **@aria }.compact }
  end

  def indicator_attrs
    colour = segmented? ? "flex gap-0.5 overflow-hidden" : TONES[@tone][:bar]
    { class: cn("rounded-full", colour, indeterminate? ? INDETERMINATE : DETERMINATE),
      style: ("width: #{percent}%" unless indeterminate?),
      data: { slot: "progress-indicator", "ui--progress-target": "indicator" } }.compact
  end

  def show_value? = @show_value && !indeterminate?

  def legend? = segmented? && @legend

  # Each segment's share of the filled part, so together they fill it; a
  # small one keeps a sliver, so it doesn't vanish.
  def segment_attrs(segment, index)
    { class: cn("h-full min-w-1", swatch(segment, index), segment.user_class),
      style: "flex: #{number(segment.value)} 1 0%", title: "#{segment.label}: #{segment_text(segment)}",
      data: { slot: "progress-segment" } }
  end

  def swatch(segment, index) = SWATCHES[segment.color] || SWATCHES[(index % SWATCHES.size) + 1]

  def segment_text(segment)
    segment.value_text ||
      (@segment_text || (whole? ? "%{percent}%" : "%{value}"))
      .gsub("%{value}", number(segment.value))
      .gsub("%{percent}", share(segment).to_s)
  end

  private

  def state
    return "indeterminate" if indeterminate?

    value >= max ? "complete" : "loading"
  end

  # Rounded, not down: shares of a whole should add up to about 100.
  def share(segment) = (segment.value / max.to_f * 100).round

  # 3, not 3.0; 2.5 stays 2.5.
  def number(n) = (n.to_f % 1).zero? ? n.to_i.to_s : n.to_s
end

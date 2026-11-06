# frozen_string_literal: true

# A line, bar, pie or donut chart: sales over a month, stock by category,
# takings by day, today's takings by payment method.
#
#   <%= render(UI::Chart.new(type: :line, label: "Sales, this year and last", format: :currency,
#         labels: %w[Jan Feb Mar], series: [
#           { name: "This year", data: [4200, 5100, 4800] },
#           { name: "Last year", data: [3900, 4300, 4500] }
#         ])) %>
#
# `type:` is :line, :bar, :pie or :donut, and `stacked: true` piles a bar
# chart's series on top of each other. A pie or donut is one total split into
# its parts: one series, a slice for each label, five at most, none below zero.
# Its legend gives each part's value and share, and a donut shows the total in
# its middle. `format:` is :number, :currency or :percent (values from 0 to
# 100), and the values are written in the app's locale: currency uses Rails'
# own format for it, or `unit:` ("₹"). `nil` leaves a gap.
#
# Each series takes the next of five colours, `--chart-1` to `--chart-5`, which
# change with the theme. A series keeps its colour by its place in the list, so
# a chart that sometimes leaves one out should give each its `color:` (1 to 5)
# to stop the others moving up. There's no sixth colour: fold the smallest
# series into "Other" instead.
#
# Two or more series get a legend, and a line ends with its last value. Hover,
# or focus the chart and use the arrow keys, for the values at each point; the
# numbers are also in a table under "Show the data", for screen readers too.
# Chart.js loads when the first chart on a page appears, and each chart draws
# when it scrolls into view: bars grow from the baseline and a line draws
# itself from left to right, unless the system asks for reduced motion.
class UI::Chart < UI::Base
  TYPES = %i[line bar pie donut].freeze
  CIRCULAR = %i[pie donut].freeze
  FORMATS = %i[number currency percent].freeze
  COLORS = 5

  # Written out in full so Tailwind finds them.
  SWATCHES = { 1 => "bg-chart-1", 2 => "bg-chart-2", 3 => "bg-chart-3", 4 => "bg-chart-4", 5 => "bg-chart-5" }.freeze

  Series = Struct.new(:name, :data, :color, keyword_init: true)

  def initialize(labels:, series:, type: :line, label: nil, stacked: false, format: :number, unit: nil, height: 288,
                 class: nil, **html_attrs)
    @labels     = labels.map(&:to_s)
    @type       = TYPES.include?(type.to_sym) ? type.to_sym : :line
    @label      = label
    @stacked    = stacked && @type == :bar
    @format     = FORMATS.include?(format.to_sym) ? format.to_sym : :number
    @unit       = unit
    @height     = height
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @series     = build_series(series)
    check_slices if circular?
  end

  attr_reader :labels, :series

  def legend? = circular? || @series.size > 1
  def line? = @type == :line
  def circular? = CIRCULAR.include?(@type)
  def swatch_classes(entry) = cn(SWATCHES[entry.color], line? ? "h-0.5 w-3.5 rounded-full" : "size-2.5 rounded-sm")

  # A pie's legend is its slices, each with its value and its share.
  Slice = Struct.new(:label, :color, :text, :share, keyword_init: true)

  def slices
    entry = @series.first
    @labels.each_with_index.map do |label, index|
      Slice.new(label: label, color: index + 1, text: formatted(entry.data[index]), share: share_text(entry.data[index]))
    end
  end

  def slice_swatch(slice) = cn(SWATCHES[slice.color], "size-2.5 shrink-0 rounded-sm")

  def legend_classes
    if circular?
      "flex flex-col gap-2 text-sm sm:w-64 sm:shrink-0"
    else
      "flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted-foreground"
    end
  end

  # A pie sits beside its legend once there's room; the others keep it above.
  def body_classes
    circular? ? "flex flex-col-reverse gap-4 sm:flex-row sm:items-center sm:gap-8" : "contents"
  end

  def root_attrs
    attrs = @html_attrs.except(:data)
    attrs[:class] = cn("flex w-full min-w-0 flex-col gap-3", @user_class)
    attrs[:data] = { slot: "chart", type: @type, controller: "ui--chart",
                     "ui--chart-config-value": config.to_json,
                     # Propshaft digests the filename, so the URL has to come from Ruby.
                     "ui--chart-module-url-value": helpers.asset_path("chart_js.js") }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  def canvas_attrs
    { role: "img", tabindex: 0, class: cn("block rounded-sm", UI::Base::FOCUS_RING),
      aria: { label: "#{label}. #{t('ui.chart.keyboard', default: 'Use the arrow keys to read each value.')}" },
      data: { "ui--chart-target": "canvas",
              action: "keydown->ui--chart#keydown blur->ui--chart#blur" } }
  end

  def frame_style = "height: #{@height.to_i}px"
  def frame_classes = cn("relative w-full", { "sm:flex-1" => circular? })

  def label = @label || t("ui.chart.label", default: "Chart")

  def formatted(value)
    return t("ui.chart.missing", default: "—") if value.nil?

    case @format
    when :currency then ActiveSupport::NumberHelper.number_to_currency(value, **{ unit: @unit }.compact)
    when :percent then ActiveSupport::NumberHelper.number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
    else ActiveSupport::NumberHelper.number_to_delimited(value)
    end
  end

  def share_text(value)
    return t("ui.chart.missing", default: "—") if value.nil? || total.zero?

    ActiveSupport::NumberHelper.number_to_percentage(value.to_f / total * 100, precision: 0)
  end

  private

  def total = @total ||= @series.first.data.compact.sum

  def check_slices
    raise ArgumentError, "a #{@type} chart shows one series; draw several as bars instead" if @series.size != 1
    if @labels.size > COLORS
      raise ArgumentError, "a #{@type} chart draws up to #{COLORS} slices; fold the rest into one called \"Other\""
    end
    raise ArgumentError, "a #{@type} chart can't show values below zero" if @series.first.data.compact.any?(&:negative?)
  end

  def build_series(series)
    if series.size > COLORS
      raise ArgumentError, "UI::Chart draws up to #{COLORS} series; fold the rest into one called \"Other\""
    end

    series.each_with_index.map do |entry, index|
      entry = entry.to_h.symbolize_keys
      data = Array(entry.fetch(:data))
      if data.size != @labels.size
        raise ArgumentError, "series #{entry[:name].inspect} has #{data.size} values for #{@labels.size} labels"
      end

      color = entry[:color].to_i.between?(1, COLORS) ? entry[:color].to_i : index + 1
      Series.new(name: entry.fetch(:name).to_s, data: data, color: color)
    end
  end

  # What the controller draws from. The values arrive written out already, so
  # the tooltip shows them the same way as the table.
  def config
    config = { type: @type, stacked: @stacked, labels: @labels,
               series: @series.map { |entry| { name: entry.name, color: entry.color, data: entry.data, text: entry.data.map { |value| formatted(value) } } },
               axis: axis_format }
    return config unless circular?

    config[:series].first.merge!(colors: (1..@labels.size).to_a, shares: @series.first.data.map { |value| share_text(value) })
    config.merge(total: formatted(total), total_label: t("ui.chart.total", default: "Total"))
  end

  # Axis ticks aren't data, so the browser writes them, in the same locale and
  # with the same currency sign.
  def axis_format
    { style: @format, locale: I18n.locale.to_s,
      unit: @unit || I18n.t("number.currency.format.unit", default: "$"),
      pattern: I18n.t("number.currency.format.format", default: "%u%n") }
  end
end

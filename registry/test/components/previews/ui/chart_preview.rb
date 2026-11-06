# frozen_string_literal: true

class UI::ChartPreview < ViewComponent::Preview
  MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze
  THIS_YEAR = [ 42_800, 39_100, 47_600, 51_200, 49_800, 56_300, 61_900, 58_400, 63_700, 66_100, 71_800, 84_500 ].freeze
  LAST_YEAR = [ 38_200, 36_900, 41_300, 44_800, 46_100, 48_700, 52_300, 51_900, 55_400, 57_800, 62_100, 73_200 ].freeze

  # @label Playground
  # @param type select { choices: [line, bar, pie, donut] }
  # @param stacked toggle
  # @param series_count number { min: 1, max: 5 }
  # @param format select { choices: [number, currency, percent] }
  def playground(type: :bar, stacked: false, series_count: 2, format: :number)
    names = %w[North South East West Online]
    # A pie or donut is one series, a slice per label, five at most.
    circular = %w[pie donut].include?(type.to_s)
    series_count = 1 if circular
    points = circular ? 5 : 6
    series = names.first(series_count.to_i).each_with_index.map do |name, i|
      { name: name, data: [ 120, 140, 135, 160, 172, 158 ].first(points).map { |v| v - (i * 18) + ((i * 7) % 11) } }
    end
    render(UI::Chart.new(type: type.to_sym, stacked: stacked, format: format.to_sym, label: "Orders by region",
                         labels: MONTHS.first(points), series: series, class: "max-w-2xl"))
  end

  # @label Sales, This Year and Last
  def sales; render_with_template; end

  # @label Stock by Category
  def stock; render_with_template; end

  # @label Takings by Payment, Stacked
  def takings; render_with_template; end

  # @label Cash Flow, Below Zero
  def cash_flow; render_with_template; end

  # @label Percentages
  def margin; render_with_template; end

  # @label Pie
  def pie; render_with_template; end

  # @label Donut, with Its Total
  def donut; render_with_template; end
end

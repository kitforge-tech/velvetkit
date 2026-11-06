# frozen_string_literal: true

require "test_helper"

class UI::ChartTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  LABELS = %w[Jan Feb Mar].freeze

  def render_chart(series: [ { name: "Sales", data: [ 1200, 1500.5, 900 ] } ], **opts)
    render_inline(UI::Chart.new(labels: LABELS, series: series, **opts))
  end

  def two_series = [ { name: "This year", data: [ 1, 2, 3 ] }, { name: "Last year", data: [ 3, 2, 1 ] } ]

  def config = JSON.parse(page.find("[data-slot='chart']")["data-ui--chart-config-value"])

  def test_renders_the_controller_with_its_module_and_a_named_canvas
    render_chart(label: "Monthly sales")
    root = page.find("[data-slot='chart'][data-controller='ui--chart'][data-type='line']")
    assert_match(/chart_js.*\.js\z/, root["data-ui--chart-module-url-value"])
    assert_selector "canvas[role='img'][tabindex='0'][data-ui--chart-target='canvas']"
    assert_includes page.find("canvas")["aria-label"], "Monthly sales."
    assert_includes page.find("canvas")["aria-label"], "arrow keys"
  end

  def test_config_carries_the_type_labels_and_series
    render_chart(type: :bar, stacked: true, series: two_series)
    assert_equal "bar", config["type"]
    assert config["stacked"]
    assert_equal LABELS, config["labels"]
    assert_equal [ "This year", "Last year" ], config["series"].map { |s| s["name"] }
    assert_equal [ 1, 2, 3 ], config["series"].first["data"]
  end

  def test_stacked_only_applies_to_bars
    render_chart(type: :line, stacked: true)
    assert_equal false, config["stacked"]
  end

  def test_unknown_type_and_format_fall_back
    render_chart(type: :radar, format: :weird)
    assert_equal "line", config["type"]
    assert_equal "number", config["axis"]["style"]
  end

  def test_series_take_the_colours_in_order_unless_given_one
    render_chart(series: [ { name: "A", data: [ 1, 2, 3 ] }, { name: "B", data: [ 1, 2, 3 ], color: 5 }, { name: "C", data: [ 1, 2, 3 ], color: 9 } ])
    assert_equal [ 1, 5, 3 ], config["series"].map { |s| s["color"] }
  end

  def test_more_than_five_series_is_refused
    six = Array.new(6) { |i| { name: "S#{i}", data: [ 1, 2, 3 ] } }
    error = assert_raises(ArgumentError) { render_chart(series: six) }
    assert_includes error.message, "Other"
  end

  def test_a_series_must_have_a_value_for_each_label
    error = assert_raises(ArgumentError) { render_chart(series: [ { name: "Short", data: [ 1, 2 ] } ]) }
    assert_includes error.message, "Short"
  end

  def test_one_series_has_no_legend
    render_chart
    assert_no_selector "ul li"
  end

  def test_two_series_get_a_legend_with_swatches_shaped_like_the_marks
    render_chart(series: two_series)
    assert_selector "ul li", count: 2
    assert_selector "ul li span.bg-chart-1.h-0\\.5"
    assert_selector "ul li", text: "Last year"
    render_chart(type: :bar, series: two_series)
    assert_selector "ul li span.bg-chart-2.size-2\\.5"
  end

  def test_table_has_every_value_written_out
    render_chart(label: "Monthly sales")
    assert_selector "details summary", text: "Show the data"
    assert_selector "table caption", text: "Monthly sales", visible: :all
    assert_selector "th[scope='col']", text: "Sales", visible: :all
    assert_selector "th[scope='row']", text: "Feb", visible: :all
    assert_selector "td", text: "1,500.5", visible: :all
  end

  def test_currency_and_percent_formats
    render_chart(format: :currency)
    assert_selector "td", text: "$1,200.00", visible: :all
    assert_equal [ "$1,200.00", "$1,500.50", "$900.00" ], config["series"].first["text"]
    render_chart(format: :currency, unit: "₹")
    assert_selector "td", text: "₹1,200.00", visible: :all
    assert_equal "₹", config["axis"]["unit"]
    render_chart(format: :percent, series: [ { name: "Margin", data: [ 38.25, 40, 41.5 ] } ])
    assert_selector "td", text: "40%", visible: :all
    assert_selector "td", text: "41.5%", visible: :all
  end

  def test_missing_values_leave_a_gap
    render_chart(series: [ { name: "Sales", data: [ 1, nil, 3 ] } ])
    assert_nil config["series"].first["data"][1]
    assert_selector "td", text: "—", visible: :all
  end

  def render_pie(type: :pie, labels: %w[Card Cash UPI], data: [ 600, 300, 100 ], **opts)
    render_inline(UI::Chart.new(type: type, labels: labels, series: [ { name: "Takings", data: data } ], **opts))
  end

  def test_pie_and_donut_are_types
    render_pie
    assert_equal "pie", config["type"]
    render_pie(type: :donut)
    assert_equal "donut", config["type"]
    assert_selector "[data-slot='chart'][data-type='donut']"
  end

  def test_pie_slices_take_the_colours_in_order_and_carry_their_shares
    render_pie
    slice = config["series"].first
    assert_equal [ 1, 2, 3 ], slice["colors"]
    assert_equal %w[60% 30% 10%], slice["shares"]
  end

  def test_pie_legend_lists_each_slice_with_its_value_and_share
    render_pie(format: :currency)
    assert_selector "ul li", count: 3
    assert_selector "ul li span.bg-chart-2.size-2\\.5"
    assert_selector "ul li", text: /Cash\s*\$300\.00\s*30%/
  end

  def test_a_single_slice_still_gets_a_legend
    render_pie(labels: %w[Card], data: [ 5 ])
    assert_selector "ul li", count: 1
  end

  def test_pie_table_adds_a_share_column
    render_pie
    assert_selector "th[scope='col']", text: "Share", visible: :all
    assert_selector "td", text: "60%", visible: :all
  end

  def test_donut_carries_its_total
    render_pie(type: :donut, format: :currency)
    assert_equal "$1,000.00", config["total"]
    assert_equal "Total", config["total_label"]
  end

  def test_line_and_bar_carry_no_slices
    render_chart
    assert_nil config["total"]
    assert_nil config["series"].first["shares"]
  end

  def test_pie_takes_one_series
    error = assert_raises(ArgumentError) do
      render_inline(UI::Chart.new(type: :pie, labels: LABELS, series: [ { name: "A", data: [ 1, 2, 3 ] }, { name: "B", data: [ 1, 2, 3 ] } ]))
    end
    assert_includes error.message, "one series"
  end

  def test_pie_draws_up_to_five_slices
    error = assert_raises(ArgumentError) { render_pie(labels: %w[a b c d e f], data: [ 1, 1, 1, 1, 1, 1 ]) }
    assert_includes error.message, "Other"
  end

  def test_pie_refuses_values_below_zero
    error = assert_raises(ArgumentError) { render_pie(data: [ 5, -1, 3 ]) }
    assert_includes error.message, "below zero"
  end

  def test_pie_with_no_total_shows_no_shares
    render_pie(data: [ 0, 0, nil ])
    assert_equal %w[— — —], config["series"].first["shares"]
  end

  def test_names_are_escaped
    render_chart(series: [ { name: "<b>Sales</b>", data: [ 1, 2, 3 ] }, { name: "Other", data: [ 1, 2, 3 ] } ])
    assert_no_selector "b"
    assert_selector "li", text: "<b>Sales</b>"
  end

  def test_height_class_and_attributes
    render_chart(height: 200, class: "max-w-xl", id: "sales", data: { foo: "bar" })
    assert_selector "#sales.max-w-xl[data-foo='bar'][data-controller='ui--chart']"
    assert_selector "div.relative[style='height: 200px'] canvas"
  end
end

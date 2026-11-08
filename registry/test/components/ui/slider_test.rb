# frozen_string_literal: true

require "test_helper"

class UI::SliderTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_slider(**opts) = render_inline(UI::Slider.new(name: "volume", **opts))

  def root = page.find("[data-slot='slider']")

  def test_renders_a_native_range_input_with_the_controller
    render_slider(value: 40)
    assert_selector "[data-slot='slider'][data-controller='ui--slider']"
    assert_selector "input[type='range'][name='volume'][value='40'][min='0'][max='100'][step='1']" \
                    "[data-ui--slider-target='input'][data-action='input->ui--slider#sync']"
    assert_selector "[data-ui--slider-target='track'][data-action='pointerdown->ui--slider#press']"
  end

  def test_each_handle_has_a_knob_drawn_after_its_input
    render_slider(value: 40)
    assert_selector "span.contents > input[type='range'].peer + span[data-slot='slider-thumb'][aria-hidden='true']"
    assert_includes page.find("[data-slot='slider-thumb']")[:style], "(100% - var(--thumb)) * var(--to)"
    render_inline(UI::Slider.new(range: true))
    knobs = page.all("[data-slot='slider-thumb']")
    assert_includes knobs[0][:style], "var(--from)"
    assert_includes knobs[1][:style], "var(--to)"
  end

  def test_takes_limits_and_step
    render_slider(value: 2.5, min: 1, max: 5, step: 0.5)
    assert_selector "input[min='1'][max='5'][step='0.5'][value='2.5']"
  end

  def test_value_is_clamped_and_snapped_to_step
    render_slider(value: 140)
    assert_selector "input[value='100']"
    render_slider(value: 23, step: 5)
    assert_selector "input[value='25']"
  end

  def test_no_value_starts_in_the_middle_as_the_browser_would
    render_slider(min: 0, max: 10)
    assert_selector "input[value='5']"
  end

  def test_fill_reaches_the_value
    render_slider(value: 25)
    assert_includes root[:style], "--from: 0;"
    assert_includes root[:style], "--to: 0.25"
    fill = page.find("[data-slot='slider-fill']")
    assert_includes fill[:style], "inset-inline-start: 0px"
    assert_includes fill[:style], "var(--to)"
  end

  def test_sizes_set_the_thumb_and_track
    render_slider(size: :lg)
    assert_includes root[:style], "--thumb: 2.25rem; --thumb-h: 1.625rem"
    assert_selector ".h-3\\.5.rounded-full"
    render_slider(size: :nonsense)
    assert_includes root[:style], "--thumb: 1.75rem; --thumb-h: 1.25rem"
  end

  def test_label_points_at_the_input
    render_slider(label: "Volume", id: "vol")
    assert_selector "label[for='vol']", text: "Volume"
    assert_selector "input#vol"
  end

  def test_value_text_is_shown_and_heard
    render_slider(value: 40, value_text: "%{value}%", show_value: true)
    assert_selector "output[aria-hidden='true'][data-ui--slider-target='output']", text: "40%"
    assert_selector "input[aria-valuetext='40%']"
    assert_equal "%{value}%", root["data-ui--slider-format-value"]
  end

  def test_value_is_not_shown_unless_asked
    render_slider(value: 40)
    assert_no_selector "output"
  end

  def test_decimals_follow_the_step
    render_slider(value: 3, min: 0, max: 5, step: 0.5, show_value: true)
    assert_selector "output", text: /\A3\z/
  end

  def test_range_has_two_handles_that_name_themselves
    render_inline(UI::Slider.new(range: true, label: "Price", from: 20, to: 80, from_name: "min", to_name: "max",
                                 id: "price"))
    assert_selector "[role='group'][aria-labelledby='price-label']"
    assert_selector "#price-label", text: "Price"
    assert_selector "label:not([for])", text: "Price"
    assert_selector "input#price[name='min'][value='20'][aria-label='Minimum']"
    assert_selector "input#price-to[name='max'][value='80'][aria-label='Maximum']"
    assert_includes root[:style], "--from: 0.2;"
    assert_includes root[:style], "--to: 0.8"
  end

  def test_range_defaults_to_the_whole_track_and_puts_values_in_order
    render_inline(UI::Slider.new(range: true))
    assert_selector "input[name='from'][value='0']"
    assert_selector "input[name='to'][value='100']"
    render_inline(UI::Slider.new(range: true, from: 70, to: 30))
    assert_selector "input[name='from'][value='30']"
    assert_selector "input[name='to'][value='70']"
  end

  def test_range_shows_both_values
    render_inline(UI::Slider.new(range: true, from: 20, to: 80, value_text: "$%{value}", show_value: true))
    assert_selector "output", text: "$20 – $80"
    assert_selector "input[aria-valuetext='$20']"
    assert_selector "input[aria-valuetext='$80']"
  end

  def test_marks_are_labelled_and_placed
    render_slider(min: 0, max: 100, marks: [ 0, 50, 100 ])
    marks = page.all("[aria-hidden='true'] span[data-action='click->ui--slider#pick']")
    assert_equal %w[0 50 100], marks.map(&:text)
    assert_equal "50", marks[1]["data-ui--slider-value-param"]
    assert_includes marks[0][:style], "inset-inline-start: 0px"
    assert_includes marks[1][:style], "calc(var(--thumb) / 2 + (100% - var(--thumb)) * 0.5)"
    assert_includes marks[2][:style], "inset-inline-start: 100%"
  end

  def test_labelled_marks_are_what_the_value_says
    render_slider(min: 1, max: 3, value: 2, show_value: true, marks: { 1 => "Low", 2 => "Medium", 3 => "High" })
    assert_selector "output", text: "Medium"
    assert_selector "input[aria-valuetext='Medium']"
    assert_equal({ "1" => "Low", "2" => "Medium", "3" => "High" }, JSON.parse(root["data-ui--slider-labels-value"]))
  end

  def test_marks_outside_the_track_are_left_out
    render_slider(min: 0, max: 10, marks: [ -5, 5, 15 ])
    assert_selector "span[data-ui--slider-value-param]", count: 1
  end

  def test_disabled_turns_off_the_input_and_the_track
    render_slider(disabled: true, marks: [ 0, 100 ])
    assert_selector "input[disabled]"
    assert_selector ".opacity-50[data-slot='slider']"
    assert_no_selector "[data-action='pointerdown->ui--slider#press']"
    assert_no_selector "span[data-action]"
  end

  def test_hint_and_error_describe_the_input
    render_slider(id: "vol", hint: "Applies to alerts", error: "Too loud")
    assert_selector "input#vol[aria-describedby='vol-hint vol-error'][aria-invalid='true']"
    assert_text "Applies to alerts"
    assert_text "Too loud"
  end

  def test_aria_names_an_unlabelled_input_or_a_range_group
    render_slider(label: false, aria: { label: "Volume" })
    assert_selector "input[aria-label='Volume']"
    assert_no_selector "[data-slot='slider'][aria-label]"
    render_inline(UI::Slider.new(range: true, aria: { label: "Price" }))
    assert_selector "[role='group'][aria-label='Price']"
  end

  def test_passes_class_and_attributes_to_the_root
    render_slider(class: "max-w-xs", data: { testid: "s" })
    assert_selector "[data-slot='slider'].max-w-xs[data-testid='s'][data-controller='ui--slider']"
  end

  Settings = Struct.new(:alert_at, :opens_at, :closes_at) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Settings")
    def persisted? = false
  end

  def builder(record) = ActionView::Helpers::FormBuilder.new(:settings, record, vc_test_controller.view_context, {})

  def test_form_binding_names_the_input_reads_the_value_and_derives_the_label
    render_inline(UI::Slider.new(form: builder(Settings.new(80)), field: :alert_at, min: 50, max: 100))
    input = page.find("input[type='range']")
    assert_equal "settings[alert_at]", input[:name]
    assert_equal "80", input[:value]
    assert_selector "label[for='#{input[:id]}']", text: "Alert at"
  end

  def test_form_binding_for_a_range
    render_inline(UI::Slider.new(range: true, form: builder(Settings.new(nil, 9, 17)), from_field: :opens_at,
                                 to_field: :closes_at, max: 24))
    assert_selector "input[name='settings[opens_at]'][value='9']"
    assert_selector "input[name='settings[closes_at]'][value='17']"
    assert_selector "label", text: "Opens at"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::ProgressSliderTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_slider(**opts) = render_inline(UI::ProgressSlider.new(name: "brightness", **opts))

  def root = page.find("[data-slot='progress-slider']")

  def test_renders_a_native_range_input_with_the_controller
    render_slider(value: 40)
    assert_selector "[data-slot='progress-slider'][data-controller='ui--progress-slider']"
    assert_selector "input[type='range'][name='brightness'][value='40'][min='0'][max='100'][step='1']" \
                    "[data-ui--progress-slider-target='input'][data-action='input->ui--progress-slider#sync']"
    assert_selector "[data-ui--progress-slider-target='track'][data-action='pointerdown->ui--progress-slider#press']"
  end

  def test_the_bar_squeezes_while_dragged_thins_as_it_stretches_and_springs_back
    render_slider
    bar = page.find("input.peer + [data-slot='progress-slider-bar']")[:class]
    assert_includes bar, "group-data-dragging/progress-slider:[transform:scale(var(--stretch,1),calc(0.6*(1-(var(--stretch,1)-1)*2.5)))]"
    assert_includes bar, "ease-[linear(0,0.078,"
    assert_includes bar, "motion-reduce:transform-none!"
  end

  def test_the_fill_and_handle_reach_the_value
    render_slider(value: 25)
    assert_includes root[:style], "--to: 0.25"
    assert_includes page.find("[data-slot='progress-slider-fill']")[:class], "w-[calc(var(--to)*100%)]"
    assert_selector "[data-slot='progress-slider-fill'] > [data-slot='progress-slider-handle'].end-1"
  end

  def shades = page.all("[data-slot='progress-slider-shade']").map { _1[:class] }

  def test_the_fade_is_grey_shading_with_the_brand_over_it_at_the_top
    render_slider(value: 99)
    grey, brand = shades
    assert_includes grey, "bg-linear-to-r rtl:bg-linear-to-l"
    assert_includes grey, "from-foreground/30 to-foreground/15"
    assert_includes brand, "from-primary to-[color-mix(in_oklab,var(--color-primary),white_30%)]"
    assert_includes brand, "opacity-0 transition-opacity duration-300 group-data-at-max/progress-slider:opacity-100"
    assert_nil root["data-at-max"]
    render_slider(value: 100)
    assert_equal "", root["data-at-max"]
    render_slider(fill: :nonsense)
    assert_equal 2, shades.size
  end

  def test_the_brand_fill_is_brand_shading_all_the_way
    render_slider(fill: :brand, value: 10)
    assert_equal 1, shades.size
    assert_includes shades.first, "from-primary"
    assert_not_includes shades.first, "opacity-0"
  end

  def test_a_range_with_no_room_is_never_at_the_top
    render_slider(min: 5, max: 5)
    assert_nil root["data-at-max"]
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

  def test_value_shows_in_the_bubble_and_the_caption_and_is_heard
    render_slider(value: 60, value_text: "%{value}%")
    assert_selector "[data-slot='progress-slider-bubble'][aria-hidden='true']", text: "60%"
    assert_selector "output[data-ui--progress-slider-target='output']", text: "60%"
    assert_selector "input[aria-valuetext='60%']"
    assert_equal "%{value}%", root["data-ui--progress-slider-format-value"]
  end

  def test_the_bubble_and_caption_can_be_left_out
    render_slider(bubble: false, show_value: false)
    assert_no_selector "[data-slot='progress-slider-bubble']"
    assert_no_selector "output"
  end

  def test_labelled_marks_are_what_the_value_says
    render_slider(min: 0, max: 4, value: 3, marks: { 0 => "Low", 1 => "Medium", 2 => "High", 3 => "Extra high", 4 => "Max" })
    assert_selector "output", text: "Extra high"
    assert_selector "input[aria-valuetext='Extra high']"
    assert_selector "[data-slot='progress-slider-bubble']", text: "Extra high"
    assert_equal({ "0" => "Low", "1" => "Medium", "2" => "High", "3" => "Extra high", "4" => "Max" },
                 JSON.parse(root["data-ui--progress-slider-labels-value"]))
  end

  def test_ticks_mark_each_step_over_the_fill
    render_slider(min: 0, max: 4)
    ticks = page.all("[data-slot='progress-slider-fill'] ~ span[aria-hidden]")
    assert_equal [ "25", "50", "75" ], ticks.map { _1[:style][/(\d+)%/, 1] }
    assert_no_selector "[data-slot='progress-slider-fill'] span[style]"
  end

  def test_ticks_are_left_out_when_there_are_too_many_unless_asked
    render_slider(max: 100)
    assert_no_selector "[data-slot='progress-slider-bar'] > span"
    render_slider(max: 30, ticks: true)
    assert_selector "[data-slot='progress-slider-bar'] > span", count: 29
    render_slider(max: 4, ticks: false)
    assert_no_selector "[data-slot='progress-slider-bar'] > span"
  end

  def test_ticks_sit_on_the_steps_when_the_step_doesnt_divide_the_range
    render_slider(max: 10, step: 3, value: 9)
    ticks = page.all("[data-slot='progress-slider-bar'] > span")
    assert_equal [ "30", "60", "90" ], ticks.map { _1[:style][/(\d+)%/, 1] }
  end

  def test_asked_for_ticks_stop_at_a_hundred
    render_slider(max: 10_000, ticks: true)
    assert_no_selector "[data-slot='progress-slider-bar'] > span"
    render_slider(max: 100, ticks: true)
    assert_selector "[data-slot='progress-slider-bar'] > span", count: 99
  end

  def test_marks_can_be_a_list_of_values_like_the_slider_takes
    render_slider(value: 50, marks: [ 0, 50, 100 ])
    assert_selector "output", text: "50"
    assert_equal({}, JSON.parse(root["data-ui--progress-slider-labels-value"]))
  end

  def test_a_blank_value_starts_in_the_middle
    render_slider(value: "", min: 0, max: 10)
    assert_selector "input[value='5']"
  end

  def test_the_bubble_stays_over_the_bar_and_shows_for_the_keyboard_only
    render_slider
    bubble = page.find("[data-slot='progress-slider-bubble']")[:class]
    assert_includes bubble, "translate-x-[clamp(calc(var(--to)*-100cqw),-50%,calc((1-var(--to))*100cqw-100%))]"
    assert_includes bubble, "peer-focus-visible:opacity-100"
    assert_not_includes bubble, "peer-focus:opacity-100"
    assert_selector "[data-ui--progress-slider-target='track'].\\@container"
  end

  def test_a_touch_screen_gets_a_taller_target_that_the_caption_doesnt_cover
    render_slider(size: :sm)
    assert_includes page.find("[data-ui--progress-slider-target='track']")[:class], "pointer-coarse:before:-inset-y-2.5"
    assert_selector "div.pointer-events-none > output"
  end

  def test_nil_options_fall_back_to_their_defaults
    render_slider(size: nil, max: nil, step: nil, value: 40)
    assert_selector "input[min='0'][max='100'][step='1'][value='40']"
    assert_selector "[data-ui--progress-slider-target='track'].h-8"
  end

  def test_a_value_that_isnt_a_number_starts_at_the_start
    render_slider(value: Float::NAN)
    assert_selector "input[value='0']"
    render_slider(value: Float::INFINITY)
    assert_selector "input[value='100']"
  end

  def test_a_controller_and_style_of_the_callers_own_go_alongside
    render_slider(data: { controller: "autosubmit", action: "change->autosubmit#submit" }, style: "max-width: 20rem")
    assert_equal "ui--progress-slider autosubmit", root["data-controller"]
    assert_equal "change->autosubmit#submit", root["data-action"]
    assert_equal "--to: 0.5; --stretch-origin: center; max-width: 20rem", root[:style]
  end

  def test_labels_are_text_not_markup
    render_slider(min: 0, max: 1, value: 1, marks: { 1 => "<b>Max</b>" })
    assert_no_selector "output b"
    assert_selector "output", text: "<b>Max</b>"
  end

  def test_it_can_be_seen_in_forced_colours
    render_slider(max: 4)
    assert_includes page.find("[data-slot='progress-slider-bar']")[:class], "forced-colors:border-[CanvasText]"
    assert_includes page.find("[data-slot='progress-slider-fill']")[:class], "forced-colors:bg-[Highlight]"
    assert_includes page.find("[data-slot='progress-slider-handle']")[:class], "forced-colors:bg-[HighlightText]"
    assert(shades.all? { _1.include?("forced-colors:hidden") })
  end

  def test_decimals_follow_the_step
    render_slider(value: 3, min: 0, max: 5, step: 0.5)
    assert_selector "output", text: /\A3\z/
  end

  def test_sizes_set_the_track_height
    render_slider(size: :lg)
    assert_selector "[data-ui--progress-slider-target='track'].h-10"
    render_slider(size: :nonsense)
    assert_selector "[data-ui--progress-slider-target='track'].h-8"
  end

  def test_room_is_kept_for_the_bubble_under_a_label
    render_slider(label: "Brightness")
    assert_selector "[data-ui--progress-slider-target='track'].mt-8"
    render_slider(label: "Brightness", bubble: false)
    assert_no_selector "[data-ui--progress-slider-target='track'].mt-8"
  end

  def test_label_points_at_the_input
    render_slider(label: "Brightness", id: "bright")
    assert_selector "label[for='bright']", text: "Brightness"
    assert_selector "input#bright"
  end

  def test_focus_rings_the_bar
    render_slider
    assert_includes page.find("[data-slot='progress-slider-bar']")[:class], "peer-focus:ring-2"
  end

  def test_disabled_turns_off_the_input_and_the_track
    render_slider(disabled: true)
    assert_selector "input[disabled]"
    assert_selector ".opacity-50[data-slot='progress-slider']"
    assert_no_selector "[data-action='pointerdown->ui--progress-slider#press']"
  end

  def test_hint_and_error_describe_the_input
    render_slider(id: "bright", hint: "Applies to every screen", error: "Too bright")
    assert_selector "input#bright[aria-describedby='bright-hint bright-error'][aria-invalid='true']"
    assert_text "Applies to every screen"
    assert_text "Too bright"
  end

  def test_aria_names_an_unlabelled_input
    render_slider(label: false, aria: { label: "Brightness" })
    assert_selector "input[aria-label='Brightness']"
    assert_no_selector "label"
  end

  def test_passes_class_and_attributes_to_the_root
    render_slider(class: "max-w-xs", data: { testid: "s" })
    assert_selector "[data-slot='progress-slider'].max-w-xs[data-testid='s'][data-controller='ui--progress-slider']"
  end

  Settings = Struct.new(:volume) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Settings")
    def persisted? = false
  end

  def builder(record) = ActionView::Helpers::FormBuilder.new(:settings, record, vc_test_controller.view_context, {})

  def test_form_binding_names_the_input_reads_the_value_and_derives_the_label
    render_inline(UI::ProgressSlider.new(form: builder(Settings.new(80)), field: :volume))
    input = page.find("input[type='range']")
    assert_equal "settings[volume]", input[:name]
    assert_equal "80", input[:value]
    assert_selector "label[for='#{input[:id]}']", text: "Volume"
  end
end

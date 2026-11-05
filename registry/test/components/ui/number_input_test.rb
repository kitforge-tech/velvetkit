# frozen_string_literal: true

require "test_helper"

class UI::NumberInputTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_input(**opts) = render_inline(UI::NumberInput.new(name: "quantity", **opts))

  def test_renders_a_number_input_in_a_group_with_the_controller
    render_input
    assert_selector "[data-slot='input-group'][data-controller='ui--number-input']"
    assert_selector "input[type='number'][name='quantity'][data-ui--number-input-target='input']"
  end

  def test_passes_value_and_limits_to_the_input
    render_input(value: 3, min: 1, max: 9, step: 2)
    assert_selector "input[value='3'][min='1'][max='9'][step='2']"
  end

  def test_leaves_out_limits_that_are_not_set
    render_input
    assert_no_selector "input[min]"
    assert_no_selector "input[max]"
    assert_no_selector "input[step]"
  end

  def test_buttons_are_named_and_point_at_the_input
    render_input(id: "qty")
    assert_selector "button[aria-label='Decrease'][aria-controls='qty'][data-ui--number-input-target='decrement']"
    assert_selector "button[aria-label='Increase'][aria-controls='qty'][data-ui--number-input-target='increment']"
    assert_selector "input#qty"
  end

  def test_buttons_do_not_submit_and_stay_out_of_the_tab_order
    render_input
    assert_selector "button[type='button'][tabindex='-1']", count: 2
  end

  def test_buttons_are_wired_to_step_in_their_direction
    render_input
    assert_selector "button[data-ui--number-input-direction-param='down'] svg[data-icon='minus']"
    assert_selector "button[data-ui--number-input-direction-param='up'] svg[data-icon='plus']"
    assert_includes page.find("button[aria-label='Increase']")["data-action"], "pointerdown->ui--number-input#press"
  end

  def test_buttons_keep_the_kits_focus_ring
    render_input
    assert_selector "button.focus\\:ring-2.focus\\:ring-primary.focus\\:z-10", count: 2
    assert_no_selector "button.focus\\:ring-0"
    assert_no_selector "[data-slot='input-group'].overflow-hidden"
  end

  def test_decrease_comes_before_the_field_and_increase_after_it
    render_input
    assert_selector "[data-align='inline-start'] button[aria-label='Decrease']"
    assert_selector "[data-align='inline-end'] button[aria-label='Increase']"
  end

  def test_label_points_at_the_field
    render_input(label: "Quantity", id: "qty")
    assert_selector "label[for='qty']", text: "Quantity"
  end

  def test_generates_an_id_for_the_label_and_buttons_to_share
    render_input(label: "Quantity")
    id = page.find("input")[:id]
    assert_selector "label[for='#{id}']"
    assert_selector "button[aria-controls='#{id}']", count: 2
  end

  def test_hint_describes_the_field
    render_input(hint: "Up to 10")
    assert_text "Up to 10"
    assert page.find("input")["aria-describedby"].present?
  end

  def test_error_marks_the_field_invalid
    render_input(error: "Too many")
    assert_text "Too many"
    assert_selector "input[aria-invalid='true']"
  end

  def test_disabled_turns_off_the_field_and_both_buttons
    render_input(disabled: true)
    assert_selector "input[disabled]"
    assert_selector "button[disabled]", count: 2
  end

  def test_readonly_keeps_the_field_and_turns_off_both_buttons
    render_input(readonly: true)
    assert_selector "input[readonly]"
    assert_no_selector "input[disabled]"
    assert_selector "button[disabled]", count: 2
  end

  def test_required_reaches_the_field
    render_input(required: true)
    assert_selector "input[required]"
  end

  def test_sizes_set_the_height_of_the_group_and_width_of_the_buttons
    { sm: %w[h-8 w-8], default: %w[h-9 w-9], lg: %w[h-12 w-12] }.each do |size, (height, width)|
      render_input(size: size)
      assert_selector "[data-slot='input-group'].#{height}"
      assert_selector "button.#{width}", count: 2
    end
  end

  def test_unknown_size_falls_back_to_default
    render_input(size: :huge)
    assert_selector "[data-slot='input-group'].h-9"
  end

  def test_keypad_suits_what_the_field_takes
    { { min: 0 } => "numeric", { min: 1, step: 2 } => "numeric", { step: 0.25 } => "decimal",
      { min: 0, step: 0.5 } => "decimal", { step: "any" } => "decimal" }.each do |opts, mode|
      render_input(**opts)
      assert_selector "input[inputmode='#{mode}']"
    end
  end

  def test_no_numeric_keypad_when_the_field_can_go_negative
    render_input
    assert_no_selector "input[inputmode]"
    render_input(min: -5)
    assert_no_selector "input[inputmode]"
  end

  def test_inputmode_can_be_overridden
    render_input(min: 0, inputmode: "text")
    assert_selector "input[inputmode='text']"
  end

  def test_data_and_actions_from_the_caller_join_the_controllers
    render_input(data: { foo: "bar", action: "change->cart#update" })
    input = page.find("input")
    assert_equal "bar", input["data-foo"]
    assert_includes input["data-action"], "change->cart#update"
    assert_includes input["data-action"], "input->ui--number-input#sync"
  end

  def test_class_reaches_the_group
    render_input(class: "w-32")
    assert_selector "[data-slot='input-group'].w-32"
  end

  def test_form_builder_names_the_field_and_fills_it_in
    item = Struct.new(:quantity).new(4)
    builder = ActionView::Helpers::FormBuilder.new(:item, item, vc_test_controller.view_context, {})
    render_inline(UI::NumberInput.new(form: builder, field: :quantity, min: 1))
    assert_selector "input[type='number'][name='item[quantity]'][value='4'][min='1']"
  end
end

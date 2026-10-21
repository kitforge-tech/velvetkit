# frozen_string_literal: true

require "test_helper"

class UI::InputGroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  # ── Wrapper ──────────────────────────────────────────────────────────────────

  def test_renders_wrapper_div_with_group_role
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "Search")
    end
    assert_selector "div[role='group'][data-slot='input-group']"
  end

  def test_wrapper_has_border_class
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "x")
    end
    wrapper = page.find("div[data-slot='input-group']")
    assert_includes wrapper[:class], "border-input"
  end

  # ── Field slot ───────────────────────────────────────────────────────────────

  def test_field_renders_input_inside_wrapper
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "Email")
    end
    assert_selector "div[data-slot='input-group'] input[placeholder='Email']"
  end

  def test_field_input_has_no_border
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "x")
    end
    inp = page.find("input")
    classes = inp[:class].split
    assert_includes classes, "border-0!"
  end

  def test_field_input_has_transparent_background
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "x")
    end
    inp = page.find("input")
    assert_includes inp[:class], "bg-transparent"
  end

  def test_field_input_has_data_slot
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "x")
    end
    assert_selector "input[data-slot='input-group-control']"
  end

  def test_field_forwards_type
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(type: :email, placeholder: "Email")
    end
    assert_selector "input[type='email']"
  end

  def test_field_error_sets_aria_invalid
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(error: true, placeholder: "x")
    end
    assert_selector "input[aria-invalid='true']"
  end

  def test_field_error_adds_destructive_class_to_wrapper
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(error: true, placeholder: "x")
    end
    wrapper = page.find("div[data-slot='input-group']")
    assert_includes wrapper[:class], "border-destructive"
  end

  def test_field_disabled_sets_disabled_on_input
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(disabled: true, placeholder: "x")
    end
    assert_selector "input[disabled]"
  end

  # ── Addon slot ───────────────────────────────────────────────────────────────

  def test_addon_renders_with_data_slot
    render_inline(UI::InputGroup.new) do |g|
      g.with_addon(align: "inline-start") { "@" }
      g.with_field(placeholder: "x")
    end
    assert_selector "[data-slot='input-group-addon']"
  end

  def test_addon_inline_start_has_order_first
    render_inline(UI::InputGroup.new) do |g|
      g.with_addon(align: "inline-start") { "pre" }
      g.with_field(placeholder: "x")
    end
    addon = page.find("[data-slot='input-group-addon']")
    assert_includes addon[:class], "order-first"
  end

  def test_addon_inline_end_has_order_last
    render_inline(UI::InputGroup.new) do |g|
      g.with_field(placeholder: "x")
      g.with_addon(align: "inline-end") { "post" }
    end
    addon = page.find("[data-slot='input-group-addon']")
    assert_includes addon[:class], "order-last"
  end

  def test_addon_renders_icon_sub_slot
    render_inline(UI::InputGroup.new) do |g|
      g.with_addon(align: "inline-start") do |addon|
        addon.with_icon(name: "mail")
      end
      g.with_field(placeholder: "Email")
    end
    assert_selector "[data-slot='input-group-addon'] i[data-lucide='mail']"
  end

  def test_multiple_addons
    render_inline(UI::InputGroup.new) do |g|
      g.with_addon(align: "inline-start") { "$" }
      g.with_addon(align: "inline-end") { ".00" }
      g.with_field(placeholder: "Amount")
    end
    assert_equal 2, page.all("[data-slot='input-group-addon']").size
  end

  # ── html_attrs passthrough ───────────────────────────────────────────────────

  def test_wrapper_html_attrs_pass_through
    render_inline(UI::InputGroup.new(id: "my-group")) do |g|
      g.with_field(placeholder: "x")
    end
    assert_selector "div#my-group[data-slot='input-group']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::RadioGroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_radiogroup_role
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free") { "Free" }
    end
    assert_selector "[role='radiogroup']"
  end

  def test_auto_generates_id
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    rg = page.find("[role='radiogroup']")
    assert rg[:id].present?
    assert rg[:id].start_with?("ui-rg-")
  end

  def test_user_class_passthrough
    render_inline(UI::RadioGroup.new(name: "plan", class: "gap-4")) { "" }
    classes = page.find("[role='radiogroup']")[:class].split
    assert_includes classes, "gap-4"
    assert_includes classes, "flex"
    assert_includes classes, "flex-col"
  end

  def test_html_attrs_passthrough
    render_inline(UI::RadioGroup.new(name: "plan", data: { test_id: "rg-x" })) { "" }
    assert_selector "[role='radiogroup'][data-test-id='rg-x']"
  end

  def test_renders_items
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    assert_equal 2, inputs.size
  end

  def test_items_share_same_name
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
      rg.with_item(value: "pro")
    end
    inputs = page.all("input[type='radio']")
    assert_equal "plan", inputs.first[:name]
    assert_equal "plan", inputs.last[:name]
  end

  def test_checked_item_reflects_group_value
    render_inline(UI::RadioGroup.new(name: "plan", value: "pro")) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    refute inputs.first["checked"].present?
    assert inputs.last["checked"].present?
  end

  def test_item_label_renders_with_for_id
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free plan")
    end
    label_el = page.find("label")
    input_el = page.find("input[type='radio']")
    assert_equal label_el["for"], input_el[:id]
    assert_match(/Free plan/, label_el.text)
  end

  def test_item_without_label_no_label_element
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    refute_selector "label"
  end

  def test_disabled_group_disables_all_items
    render_inline(UI::RadioGroup.new(name: "plan", disabled: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    inputs.each { |i| assert i.disabled? }
  end

  def test_required_group_sets_required_on_items
    render_inline(UI::RadioGroup.new(name: "plan", required: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
      rg.with_item(value: "pro", label: "Pro")
    end
    inputs = page.all("input[type='radio']")
    inputs.each { |i| assert i["required"].present? }
  end

  def test_required_label_shows_asterisk
    render_inline(UI::RadioGroup.new(name: "plan", required: true)) do |rg|
      rg.with_item(value: "free", label: "Free")
    end
    label_el = page.find("label")
    assert_match(/Free \*/, label_el.text)
  end

  def test_disabled_item_wrapper_dims
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free", label: "Free", disabled: true)
    end
    label_el = page.find("label")
    classes = label_el[:class].split
    assert_includes classes, "cursor-not-allowed"
    assert_includes classes, "opacity-60"
  end

  def test_item_dot_appears_when_checked
    render_inline(UI::RadioGroup.new(name: "plan", value: "pro")) do |rg|
      rg.with_item(value: "pro", label: "Pro")
    end
    input = page.find("input[type='radio'][checked]")
    dot = page.find("span.rounded-full.bg-primary-foreground", visible: :all)
    classes = dot[:class].split
    assert_includes classes, "bg-primary-foreground"
  end

  def test_item_box_has_rounded_full_and_checked_states
    render_inline(UI::RadioGroup.new(name: "plan")) do |rg|
      rg.with_item(value: "free")
    end
    classes = page.find("input[type='radio']")[:class].split
    assert_includes classes, "rounded-full"
    assert_includes classes, "peer"
    assert_includes classes, "appearance-none"
  end
end

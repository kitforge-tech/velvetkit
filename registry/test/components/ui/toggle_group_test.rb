# frozen_string_literal: true

require "test_helper"

class UI::ToggleGroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  Post = Struct.new(:align, :styles) do
    def self.model_name = ActiveModel::Name.new(self, nil, "Post")
  end

  def render_group(**opts)
    render_inline(UI::ToggleGroup.new(name: "view", label: "View", **opts)) do |group|
      group.with_item(value: "list", label: "List")
      group.with_item(value: "grid", label: "Grid")
      group.with_item(value: "board", label: "Board", disabled: true)
    end
  end

  def test_single_is_a_radiogroup_of_radios
    render_group(value: "grid")
    group = page.find("[role='radiogroup'][aria-label='View']")
    assert_equal 3, group.all("input[type='radio'][name='view']", visible: :all).size
    assert page.find("input[value='grid']", visible: :all).checked?
    refute page.find("input[value='list']", visible: :all).checked?
  end

  def test_each_input_is_inside_its_label
    render_group
    assert_selector "label[data-slot='toggle-group-item'] input[value='list']", visible: :all
    assert_selector "label[data-slot='toggle-group-item'] span", text: "List"
  end

  def test_multiple_is_a_group_of_checkboxes_with_an_empty_value
    render_inline(UI::ToggleGroup.new(name: "styles", value: %w[bold italic], multiple: true)) do |group|
      group.with_item(value: "bold", label: "Bold")
      group.with_item(value: "italic", label: "Italic")
      group.with_item(value: "underline", label: "Underline")
    end
    assert_selector "[role='group']"
    assert_equal 3, page.all("input[type='checkbox'][name='styles[]']", visible: :all).size
    assert_selector "input[type='hidden'][name='styles[]'][value='']", visible: :all
    checked = page.all("input[type='checkbox']", visible: :all).select(&:checked?).map(&:value)
    assert_equal %w[bold italic], checked
  end

  def test_values_compare_as_strings
    render_inline(UI::ToggleGroup.new(name: "size", value: :md)) do |group|
      group.with_item(value: :sm, label: "S")
      group.with_item(value: :md, label: "M")
    end
    assert page.find("input[value='md']", visible: :all).checked?
  end

  def test_item_disabled
    render_group
    assert page.find("input[value='board']", visible: :all).disabled?
    refute page.find("input[value='list']", visible: :all).disabled?
  end

  def test_group_disabled
    render_group(disabled: true)
    assert(page.all("input", visible: :all).all?(&:disabled?))
  end

  def test_required_marks_the_radios
    render_group(required: true)
    assert_equal 3, page.all("input[required]", visible: :all).size
  end

  def test_required_is_ignored_when_multiple
    render_inline(UI::ToggleGroup.new(name: "s", multiple: true, required: true)) do |group|
      group.with_item(value: "a", label: "A")
    end
    assert_no_selector "input[required]", visible: :all
  end

  def test_form_builder_names_and_values
    form = ActionView::Helpers::FormBuilder.new(:post, Post.new("center", nil), vc_test_controller.view_context, {})
    render_inline(UI::ToggleGroup.new(form: form, field: :align)) do |group|
      group.with_item(value: "left", label: "Left")
      group.with_item(value: "center", label: "Center")
    end
    assert_selector "input[name='post[align]']", count: 2, visible: :all
    assert page.find("input[value='center']", visible: :all).checked?
  end

  def test_form_builder_multiple
    form = ActionView::Helpers::FormBuilder.new(:post, Post.new(nil, %w[italic]), vc_test_controller.view_context, {})
    render_inline(UI::ToggleGroup.new(form: form, field: :styles, multiple: true)) do |group|
      group.with_item(value: "bold", label: "Bold")
      group.with_item(value: "italic", label: "Italic")
    end
    assert_selector "input[type='checkbox'][name='post[styles][]']", count: 2, visible: :all
    assert page.find("input[value='italic']", visible: :all).checked?
  end

  def test_default_variant_is_a_muted_track
    render_group
    classes = page.find("[data-slot='toggle-group']")[:class].split
    assert_includes classes, "bg-muted"
    assert_includes classes, "rounded-lg"
    assert_includes page.find("label", text: "List")[:class].split, "has-[:checked]:bg-background"
  end

  def test_outline_variant
    render_group(variant: :outline)
    root = page.find("[data-slot='toggle-group'][data-variant='outline']")
    assert_includes root[:class].split, "border"
    assert_includes root[:class].split, "divide-x"
    item = page.find("label", text: "List")[:class].split
    assert_includes item, "has-[:checked]:bg-foreground/8"
    assert_includes item, "text-muted-foreground"
    assert_includes item, "hover:text-foreground"
    refute(item.any? { |c| c.include?("hover:bg-") }, "hover must not tint the background")
  end

  def test_sizes
    { sm: "h-7", default: "h-8", lg: "h-9" }.each do |size, height|
      render_group(size: size)
      assert_includes page.find("label", text: "List")[:class].split, height, size.to_s
    end
  end

  def test_icon_with_text
    render_inline(UI::ToggleGroup.new(name: "view")) do |group|
      group.with_item(value: "list", label: "List", icon: "list")
    end
    assert_selector "label svg[data-icon='list']", visible: :all
    assert_selector "label span", text: "List"
    assert_nil page.find("label")[:title]
  end

  def test_icon_only_keeps_a_hidden_name_and_a_tooltip
    render_inline(UI::ToggleGroup.new(name: "align")) do |group|
      group.with_item(value: "left", label: "Align left", icon: "align-left", icon_only: true)
    end
    label = page.find("label")
    assert_equal "Align left", label[:title]
    assert_selector "label span.sr-only", text: "Align left", visible: :all
    assert_includes label[:class].split, "w-8"
  end

  def test_block_is_the_item_text
    render_inline(UI::ToggleGroup.new(name: "plan")) do |group|
      group.with_item(value: "yearly") { "Yearly" }
    end
    assert_selector "label span", text: "Yearly"
  end

  def test_user_class_and_attrs_pass_through
    render_inline(UI::ToggleGroup.new(name: "v", id: "view-switch", class: "w-full",
                                      data: { action: "change->filters#apply" })) do |group|
      group.with_item(value: "a", label: "A", class: "flex-1", data: { test_id: "a" })
    end
    root = page.find("#view-switch[data-slot='toggle-group'][data-action='change->filters#apply']")
    assert_includes root[:class].split, "w-full"
    refute_includes root[:class].split, "w-fit"
    assert_selector "label.flex-1[data-test-id='a'][data-slot='toggle-group-item']"
  end
end

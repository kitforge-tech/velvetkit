# frozen_string_literal: true

require "test_helper"

class UI::LabelTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_default
    render_inline(UI::Label.new) { "Email" }
    assert_selector "label", text: "Email"
  end

  def test_renders_label_tag
    render_inline(UI::Label.new) { "Name" }
    assert_selector "label"
    refute_selector "div"
  end

  def test_default_size_classes
    render_inline(UI::Label.new) { "Label" }
    lbl = page.find("label")
    assert_includes lbl[:class], "text-sm"
  end

  def test_size_xs
    render_inline(UI::Label.new(size: :xs)) { "Tiny" }
    assert_selector "label.text-xs"
  end

  def test_size_sm
    render_inline(UI::Label.new(size: :sm)) { "Small" }
    assert_selector "label.text-sm"
  end

  def test_size_lg
    render_inline(UI::Label.new(size: :lg)) { "Large" }
    assert_selector "label.text-base"
  end

  def test_weight_normal
    render_inline(UI::Label.new(weight: :normal)) { "Light" }
    lbl = page.find("label")
    assert_includes lbl[:class], "font-normal"
  end

  def test_weight_medium_is_default
    render_inline(UI::Label.new) { "Default" }
    lbl = page.find("label")
    assert_includes lbl[:class], "font-medium"
  end

  def test_weight_semibold
    render_inline(UI::Label.new(weight: :semibold)) { "Bold" }
    lbl = page.find("label")
    assert_includes lbl[:class], "font-semibold"
  end

  def test_for_attribute_passes_through
    render_inline(UI::Label.new(for: "email_field")) { "Email" }
    assert_selector "label[for='email_field']", text: "Email"
  end

  def test_required_appends_asterisk
    render_inline(UI::Label.new(required: true)) { "Name" }
    lbl = page.find("label")
    assert_match(/Name/, lbl.text)
    assert_selector "label span", text: "*"
  end

  def test_required_false_does_not_append_asterisk
    render_inline(UI::Label.new(required: false)) { "Name" }
    refute_selector "label span"
  end

  def test_disabled_applies_muted_class
    render_inline(UI::Label.new(disabled: true)) { "Off" }
    lbl = page.find("label")
    classes = lbl[:class].split
    assert_includes classes, "text-muted-foreground"
    assert_includes classes, "cursor-not-allowed"
  end

  def test_user_class_overrides_default_via_tailwind_merge
    render_inline(UI::Label.new(class: "text-lg")) { "Override" }
    lbl = page.find("label")
    classes = lbl[:class].split
    refute_includes classes, "text-sm"
    assert_includes classes, "text-lg"
  end

  def test_html_attrs_pass_through
    render_inline(UI::Label.new(id: "my-label", data: { test_id: "lbl" })) { "Test" }
    assert_selector "label#my-label[data-test-id='lbl']", text: "Test"
  end
end

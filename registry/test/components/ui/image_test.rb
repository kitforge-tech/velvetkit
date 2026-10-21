# frozen_string_literal: true

require "test_helper"

class UI::ImageTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_img_with_asset_path
    render_inline(UI::Image.new(src: "brand-logo.svg"))
    assert_selector "img"
    assert_match %r{/(assets/)?brand-logo}, page.find("img")[:src]
  end

  def test_default_rounded_and_base_classes
    render_inline(UI::Image.new(src: "brand-logo.svg"))
    classes = page.find("img")[:class].split
    assert_includes classes, "rounded-sm"
    assert_includes classes, "block"
    assert_includes classes, "max-w-full"
  end

  def test_rounded_variant
    render_inline(UI::Image.new(src: "brand-logo.svg", rounded: :lg))
    classes = page.find("img")[:class].split
    assert_includes classes, "rounded-lg"
    refute_includes classes, "rounded-sm"
  end

  # Velvet sized the wrapper div instead of the image; these must land on <img>.
  def test_width_and_height_apply_to_the_image
    render_inline(UI::Image.new(src: "brand-logo.svg", width: "14px", height: "20px"))
    style = page.find("img")[:style]
    assert_includes style, "width: 14px"
    assert_includes style, "height: 20px"
  end

  def test_numeric_dimensions_get_px_units
    render_inline(UI::Image.new(src: "brand-logo.svg", width: 42))
    assert_includes page.find("img")[:style], "width: 42px"
  end

  def test_omits_style_when_no_dimensions_given
    render_inline(UI::Image.new(src: "brand-logo.svg"))
    assert_nil page.find("img")[:style].presence
  end

  def test_alt_defaults_to_humanized_filename
    render_inline(UI::Image.new(src: "brand-logo.png"))
    assert_equal "Brand logo", page.find("img")[:alt]
  end

  def test_explicit_alt_wins
    render_inline(UI::Image.new(src: "brand-logo.png", alt: "Brand logo"))
    assert_equal "Brand logo", page.find("img")[:alt]
  end

  def test_lazy_loading_by_default
    render_inline(UI::Image.new(src: "brand-logo.svg"))
    assert_equal "lazy", page.find("img")[:loading]
  end

  def test_user_class_override_via_tailwind_merge
    render_inline(UI::Image.new(src: "brand-logo.svg", rounded: :lg, class: "rounded-none"))
    classes = page.find("img")[:class].split
    assert_includes classes, "rounded-none"
    refute_includes classes, "rounded-lg"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Image.new(src: "brand-logo.svg", id: "logo", data: { test_id: "img" }))
    assert_selector "img#logo[data-test-id='img']"
  end
end

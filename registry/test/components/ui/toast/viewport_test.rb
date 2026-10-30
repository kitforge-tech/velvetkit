# frozen_string_literal: true

require "test_helper"

class UI::Toast::ViewportTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def viewport_el
    page.find("##{UI::Toast::Viewport::ID}", visible: :all)
  end

  def test_renders_with_default_id
    render_inline(UI::Toast::Viewport.new)
    assert_equal "ui-toast-viewport", viewport_el["id"]
  end

  def test_renders_with_custom_id
    render_inline(UI::Toast::Viewport.new(id: "my-toasts"))
    assert page.has_css?("#my-toasts", visible: :all)
  end

  def test_default_position_is_bottom_right
    render_inline(UI::Toast::Viewport.new)
    classes = viewport_el[:class].split
    assert_includes classes, "bottom-0"
    assert_includes classes, "right-0"
    assert_includes classes, "items-end"
  end

  def test_top_position_reverses_stack_order
    render_inline(UI::Toast::Viewport.new(position: :top_right))
    classes = viewport_el[:class].split
    assert_includes classes, "top-0"
    assert_includes classes, "flex-col-reverse"
  end

  def test_data_controller
    render_inline(UI::Toast::Viewport.new)
    assert_equal "ui--toast-viewport", viewport_el["data-controller"]
  end

  def test_renders_one_template_per_variant
    render_inline(UI::Toast::Viewport.new)
    templates = page.all("template[data-ui--toast-viewport-target='template']", visible: :all)
    assert_equal UI::Toast::Viewport::VARIANTS.map(&:to_s).sort,
                 templates.map { |t| t["data-variant"] }.sort
  end

  def test_templates_carry_title_and_description_targets
    # Capybara's rack_test driver parses <template> as an ordinary element
    # with no HTML5 content fragment, so its children never show up through
    # Capybara/Nokogiri node traversal; assert on the raw markup instead.
    html = render_inline(UI::Toast::Viewport.new).to_html
    UI::Toast::Viewport::VARIANTS.each do |variant|
      template_html = html[/<template[^>]*data-variant="#{variant}"[^>]*>(.*?)<\/template>/m, 1]
      assert template_html, "no template found for #{variant}"
      assert_includes template_html, "data-ui--toast-target=\"title\""
      assert_includes template_html, "data-ui--toast-target=\"description\""
    end
  end

  def test_user_class_merge
    render_inline(UI::Toast::Viewport.new(class: "my-viewport"))
    assert_includes viewport_el[:class].split, "my-viewport"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Toast::Viewport.new(data: { test_id: "v" }))
    assert_equal "v", viewport_el["data-test-id"]
  end
end

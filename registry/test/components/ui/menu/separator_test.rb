# frozen_string_literal: true

require "test_helper"

class UI::Menu::SeparatorTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_separator
    render_inline(UI::Menu::Separator.new)
    assert_selector "[role='separator']"
  end

  def test_has_horizontal_orientation
    render_inline(UI::Menu::Separator.new)
    sep = page.find("[role='separator']")
    assert_equal "horizontal", sep[:"aria-orientation"]
  end

  def test_has_styling
    render_inline(UI::Menu::Separator.new)
    sep = page.find("[role='separator']")
    assert sep[:class].include?("bg-muted")
    assert sep[:class].include?("h-px")
  end

  def test_custom_class_merge
    render_inline(UI::Menu::Separator.new(class: "custom-sep"))
    sep = page.find("[role='separator']")
    assert_includes sep[:class].split, "custom-sep"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::Menu::GroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    render_inline(UI::Menu::Group.new) { "Group content" }
    assert_text "Group content"
  end

  def test_has_role_group
    render_inline(UI::Menu::Group.new) { "Group" }
    assert_selector "[role='group']"
  end

  def test_custom_class_merge
    render_inline(UI::Menu::Group.new(class: "custom-group")) { "Group" }
    group = page.find("[role='group']")
    assert_includes group[:class].split, "custom-group"
  end
end

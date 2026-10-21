# frozen_string_literal: true

require "test_helper"

class UI::Sidebar::MenuButtonTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_active_button_sets_data_active
    render_inline(UI::Sidebar::MenuButton.new("#", active: true)) { "Dashboard" }
    link = page.find("a", text: "Dashboard")
    assert_equal "true", link[:"data-active"]
    assert_includes link[:class], "data-[active=true]:bg-sidebar-primary/10"
  end

  # Active is a primary tint while hover stays the neutral sidebar accent, so
  # hovering an inactive item can't be mistaken for the current page.
  def test_active_styling_is_distinct_from_hover
    render_inline(UI::Sidebar::MenuButton.new("#", active: true)) { "Dashboard" }
    classes = page.find("a", text: "Dashboard")[:class]
    assert_includes classes, "data-[active=true]:text-sidebar-primary"
    assert_includes classes, "data-[active=true]:font-semibold"
    assert_includes classes, "hover:bg-sidebar-accent"
  end

  def test_allows_aria_current
    render_inline(UI::Sidebar::MenuButton.new("#", current: "page")) { "Dashboard" }
    link = page.find("a", text: "Dashboard")
    assert_equal "page", link[:"aria-current"]
  end

  def test_active_sets_aria_current_page_by_default
    render_inline(UI::Sidebar::MenuButton.new("#", active: true)) { "Dashboard" }
    link = page.find("a", text: "Dashboard")
    assert_equal "page", link[:"aria-current"]
  end

  def test_active_does_not_override_explicit_current
    render_inline(UI::Sidebar::MenuButton.new("#", active: true, current: "step")) { "Dashboard" }
    link = page.find("a", text: "Dashboard")
    assert_equal "step", link[:"aria-current"]
  end
end

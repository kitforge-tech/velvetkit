# frozen_string_literal: true

require "test_helper"

class UI::Sidebar::WrapperTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_controller_and_css_vars
    render_inline(UI::Sidebar::Wrapper.new) { "x" }
    wrapper = page.find("[data-controller~='ui--sidebar']")
    assert_includes wrapper[:class], "group/sidebar-wrapper"
    assert_includes wrapper[:style], "--sidebar-width:"
  end
end

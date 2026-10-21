# frozen_string_literal: true

require "test_helper"

class UI::Sidebar::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_trigger_wires_toggle_action
    render_inline(UI::Sidebar::Trigger.new(sidebar_id: "main-sidebar"))
    button = page.find("button")
    assert_equal "main-sidebar", button[:"aria-controls"]
    assert_equal "true", button[:"aria-expanded"]
    assert_equal "Toggle sidebar", button[:"aria-label"]
    assert button[:"data-action"].include?("ui--sidebar#toggle")
  end
end

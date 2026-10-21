# frozen_string_literal: true

require "test_helper"

class UI::Sheet::TriggerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_trigger_reuses_dialog_behavior
    render_inline(UI::Sheet.new(id: "profile-sheet")) do |sheet|
      sheet.with_trigger { "Open" }
      sheet.with_content { |c| c.with_title("Hi") }
    end

    trigger = page.find("[data-ui--dialog-target='trigger']")
    assert_equal "dialog", trigger["aria-haspopup"]
    assert_equal "profile-sheet", trigger["aria-controls"]
    assert trigger["data-action"].include?("click->ui--dialog#open")
    assert_equal "Open", trigger.text.strip
    # Should render as UI::Button by default
    assert_includes trigger[:class].split, "bg-primary"
  end
end

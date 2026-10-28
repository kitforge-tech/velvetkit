# frozen_string_literal: true

require "test_helper"

class UI::FormField::MessagesTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_hint_and_error_with_ids
    render_inline(UI::FormField::Messages.new(UI::FormField.new(hint: "Hint", error: "Error", for: "f")))
    assert_selector "p#f-hint", text: "Hint"
    assert_selector "p#f-error", text: "Error"
  end

  def test_renders_nothing_without_messages
    render_inline(UI::FormField::Messages.new(UI::FormField.new(error: true, for: "f")))
    refute_selector "p"
  end
end

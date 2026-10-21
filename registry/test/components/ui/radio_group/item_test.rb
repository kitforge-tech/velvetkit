# frozen_string_literal: true

require "test_helper"

class UI::RadioGroup::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_render_without_group_context_returns_nothing
    item = UI::RadioGroup::Item.new(value: "free", label: "Free")
    render_inline(item)
    refute page.text.present?
  end
end

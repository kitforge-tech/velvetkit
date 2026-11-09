# frozen_string_literal: true

require "test_helper"

class UI::Card::ActionTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_sits_in_the_headers_second_column
    render_inline(UI::Card::Action.new) { "Invite" }
    action = page.find("[data-slot='card-action']", text: "Invite")
    %w[col-start-2 row-span-2 row-start-1 justify-self-end].each { |c| assert_includes action[:class].split, c }
  end

  def test_passes_class_and_attributes
    render_inline(UI::Card::Action.new(class: "self-center", id: "a", data: { testid: "t" })) { "x" }
    assert_selector "#a.self-center[data-testid='t'][data-slot='card-action']"
  end
end

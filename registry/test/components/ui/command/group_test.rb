# frozen_string_literal: true

require "test_helper"

class UI::Command::GroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_a_group_named_by_its_heading
    render_inline(UI::Command::Group.new(heading: "Pages")) { |g| g.with_item(label: "Home", href: "/") }
    heading = page.find("[role='group'] > div", text: "Pages")
    assert_selector "[role='group'][data-ui--command-target='group'][aria-labelledby='#{heading[:id]}'] [role='option']", text: "Home"
  end

  def test_a_group_without_a_heading
    render_inline(UI::Command::Group.new(class: "pt-0")) { |g| g.with_item(label: "Home") }
    assert_selector "[role='group'].pt-0:not([aria-labelledby])"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::StepperTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_stepper(current: 2, **opts, &block)
    block ||= lambda do |stepper|
      stepper.with_step(title: "Account", description: "Your details", href: "/signup/account")
      stepper.with_step(title: "Plan", href: "/signup/plan")
      stepper.with_step(title: "Payment")
    end
    render_inline(UI::Stepper.new(current: current, **opts), &block)
  end

  def step(title) = page.find("li", text: title)

  def test_a_labelled_nav_around_an_ordered_list
    render_stepper
    assert_selector "nav[aria-label='Progress'][data-slot='stepper'] ol > li", count: 3
  end

  def test_label_can_be_changed
    render_stepper(label: "Sign-up progress")
    assert_selector "nav[aria-label='Sign-up progress']"
  end

  def test_states_follow_current
    render_stepper(current: 2)
    assert_equal %w[complete current upcoming], page.all("li").map { |li| li["data-status"] }
  end

  def test_current_step_has_aria_current
    render_stepper(current: 2)
    assert_equal "step", step("Plan")["aria-current"]
    assert_nil step("Account")["aria-current"]
    assert_selector "li[aria-current]", count: 1
  end

  def test_past_the_last_step_marks_them_all_complete
    render_stepper(current: 4)
    assert_equal %w[complete complete complete], page.all("li").map { |li| li["data-status"] }
    assert_no_selector "li[aria-current]"
  end

  def test_complete_steps_show_a_check_others_a_number
    render_stepper(current: 2)
    assert step("Account").has_selector?("svg[data-icon='check']", visible: :all)
    assert step("Plan").has_selector?("span[aria-hidden='true']", text: "2")
    assert step("Payment").has_selector?("span[aria-hidden='true']", text: "3")
  end

  def test_error_status_overrides_and_shows_an_alert
    render_stepper(current: 3) do |stepper|
      stepper.with_step(title: "Account", status: :error)
      stepper.with_step(title: "Plan")
      stepper.with_step(title: "Payment")
    end
    assert_equal "error", step("Account")["data-status"]
    assert step("Account").has_selector?("svg[data-icon='circle-alert']", visible: :all)
    assert_equal "complete", step("Plan")["data-status"]
  end

  def test_screen_readers_hear_each_state
    render_stepper(current: 2)
    assert step("Account").has_selector?(".sr-only", text: "Completed", visible: :all)
    assert step("Plan").has_selector?(".sr-only", text: "Current step", visible: :all)
    assert step("Payment").has_selector?(".sr-only", text: "Not started", visible: :all)
  end

  def test_steps_with_href_link_except_the_current_one
    render_stepper(current: 2)
    assert_selector "li a[href='/signup/account']", text: "Account"
    assert_no_selector "a[href='/signup/plan']"
    assert_selector "a", count: 1
  end

  def test_description
    render_stepper
    assert_selector "li span", text: "Your details"
  end

  def test_horizontal_on_a_phone_shows_only_the_current_title
    render_stepper(current: 2)
    assert_includes page.find("span", exact_text: "Your details")[:class].split, "max-sm:sr-only"
    assert_includes step("Account").find("span", exact_text: "Account").ancestor("span")[:class].split, "max-sm:sr-only"
    refute_includes step("Plan").find("span", exact_text: "Plan").ancestor("span")[:class].split, "max-sm:sr-only"
  end

  def test_vertical_keeps_descriptions
    render_stepper(orientation: :vertical)
    assert_selector "nav[data-orientation='vertical'] ol.flex-col"
    refute_includes page.find("span", exact_text: "Your details")[:class].split, "max-sm:sr-only"
  end

  def test_a_connector_after_every_step_but_the_last
    render_stepper(current: 2)
    assert_equal 2, page.all("li > div[aria-hidden='true']", visible: :all).size
    assert_includes step("Account").find("div[aria-hidden='true']", visible: :all)[:class].split, "bg-primary"
    assert_includes step("Plan").find("div[aria-hidden='true']", visible: :all)[:class].split, "bg-border"
    assert_no_selector "li:last-child > div[aria-hidden='true']", visible: :all
  end

  def test_user_class_and_attrs
    render_stepper(id: "signup-steps", class: "max-w-xl", data: { test_id: "steps" })
    assert_selector "nav#signup-steps[data-test-id='steps'][data-slot='stepper'] ol.max-w-xl"
  end

  def test_step_class_and_attrs
    render_stepper do |stepper|
      stepper.with_step(title: "Only", class: "pr-4", data: { test_id: "only" })
    end
    assert_selector "li.pr-4[data-test-id='only'][data-slot='stepper-step']"
  end
end

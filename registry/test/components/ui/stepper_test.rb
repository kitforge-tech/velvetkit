# frozen_string_literal: true

require "test_helper"

class UI::StepperTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_steps(titles = %w[Account Plan Payment], **opts, &block)
    render_inline(UI::Stepper.new(**opts)) do |stepper|
      titles.each { |title| stepper.with_step(title: title) }
      block&.call(stepper)
    end
  end

  def statuses = page.all("li[data-slot='stepper-step']").map { |li| li["data-status"] }

  def test_renders_a_labelled_nav_with_an_ordered_list
    render_steps
    assert_selector "nav[aria-label='Progress'] > ol > li", count: 3
    assert_selector "div[data-slot='stepper'][data-orientation='horizontal'][data-variant='default']"
  end

  def test_label_names_the_nav
    render_steps(label: "Create a project")
    assert_selector "nav[aria-label='Create a project']"
  end

  def test_steps_before_current_are_complete_and_after_are_upcoming
    render_steps(%w[A B C D], current: 3)
    assert_equal %w[complete complete current upcoming], statuses
    assert_selector "li[data-status='current'][aria-current='step']", text: "C"
    assert_selector "li[aria-current]", count: 1
  end

  def test_current_past_the_last_step_marks_them_all_complete
    render_steps(current: 4)
    assert_equal %w[complete complete complete], statuses
    refute_selector "li[aria-current]"
  end

  def test_status_overrides_the_step
    render_inline(UI::Stepper.new(current: 2)) do |stepper|
      stepper.with_step(title: "Build")
      stepper.with_step(title: "Test", status: :error)
      stepper.with_step(title: "Deploy", status: :loading)
    end
    assert_equal %w[complete error loading], statuses
  end

  def test_each_step_says_its_state_to_screen_readers
    render_steps(current: 2)
    step = page.find("li[data-status='complete']")
    assert_includes step.find("span.sr-only", text: "Completed", visible: :all)[:class], "group-data-[status=complete]/step:inline"
  end

  def test_indicator_draws_the_number_and_a_glyph_for_each_state
    render_steps(current: 2)
    indicator = page.find_all("li")[1].find("span[aria-hidden]", match: :first)
    assert_text "2"
    assert_selector "li svg[data-icon='check']", visible: :all
    assert_selector "li svg[data-icon='loader'].animate-spin", visible: :all
    assert_includes indicator[:class], "group-data-[status=current]/step:ring-4"
  end

  def test_icon_replaces_the_number
    render_inline(UI::Stepper.new) { |stepper| stepper.with_step(title: "Pay", icon: "credit-card") }
    assert_selector "li svg[data-icon='credit-card']", visible: :all
  end

  def test_connector_between_steps_but_not_after_the_last
    render_steps
    assert_selector "li span.bg-border", count: 2
    refute_selector "li:last-child span.bg-border"
  end

  def test_connector_fill_grows_once_the_step_is_done
    render_steps
    fill = page.find("li span.bg-border > span", match: :first, visible: :all)
    assert_includes fill[:class], "scale-x-0"
    assert_includes fill[:class], "group-data-[status=complete]/step:scale-x-100"
  end

  def test_no_connector
    render_steps(connector: false)
    refute_selector "li span.bg-border"
  end

  def test_vertical_stacks_with_a_vertical_line
    render_steps(orientation: :vertical)
    assert_selector "div[data-orientation='vertical'] ol.flex-col"
    fill = page.find("li span.bg-border > span", match: :first, visible: :all)
    assert_includes fill[:class], "group-data-[status=complete]/step:scale-y-100"
  end

  def test_dot_variant_draws_no_number
    render_steps(variant: :dot)
    assert_selector "div[data-variant='dot']"
    refute_selector "li span.size-8"
    assert_selector "li span.size-3", count: 3
    assert page.all("li span.size-3").all? { |dot| dot.text.strip.empty? }
  end

  def test_center_align_centres_each_step
    render_steps(align: :center)
    assert_selector "li.items-center.text-center", count: 3
  end

  def test_labels_false_keeps_titles_for_screen_readers
    render_steps(labels: false)
    assert_selector "li div.sr-only", count: 3, visible: :all
  end

  def test_titles_are_hidden_on_phones_with_a_summary_instead
    render_steps(current: 2)
    assert_selector "li div.\\@max-md\\/stepper\\:sr-only", count: 3, visible: :all
    summary = page.find("p.\\@md\\/stepper\\:hidden[aria-hidden='true']")
    assert_equal "Step 2 of 3: Plan", summary.text
  end

  def test_descriptions
    render_inline(UI::Stepper.new) { |stepper| stepper.with_step(title: "Account", description: "Name and email") }
    assert_selector "li span", text: "Name and email"
  end

  def test_done_steps_with_href_link_back_but_the_current_one_does_not
    render_inline(UI::Stepper.new(current: 2)) do |stepper|
      stepper.with_step(title: "Account", href: "/signup/account")
      stepper.with_step(title: "Plan", href: "/signup/plan")
    end
    assert_selector "a[href='/signup/account']", text: "Account"
    refute_selector "a[href='/signup/plan']"
  end

  def test_wires_the_controller_with_the_current_step
    render_steps(current: 2)
    root = page.find("div[data-slot='stepper']")
    controller = "ui--stepper"
    assert_equal controller, root["data-controller"]
    assert_equal "2", root["data-#{controller}-current-value"]
    assert_equal "Step %{current} of %{total}", root["data-#{controller}-summary-value"]
    assert_includes root["data-action"], "#{controller}#keydown"
    assert_selector "li[data-#{controller}-target='step']", count: 3
  end

  def test_step_blocks_become_panels_and_only_the_current_one_shows
    render_inline(UI::Stepper.new(current: 2)) do |stepper|
      stepper.with_step(title: "Account") { "Account fields" }
      stepper.with_step(title: "Plan") { "Plan fields" }
    end
    panels = page.all("div[role='group'][data-step]", visible: :all)
    assert_equal %w[1 2], panels.map { |panel| panel["data-step"] }
    assert panels.first[:hidden]
    refute panels.last[:hidden]
    assert_text "Plan fields"
    assert_equal panels.last["aria-labelledby"], page.find("li span", text: "Plan", exact_text: true)[:id]
    refute_selector "li", text: "Plan fields"
  end

  def test_inline_layout_puts_each_panel_in_its_step
    render_inline(UI::Stepper.new(orientation: :vertical, layout: :inline)) do |stepper|
      stepper.with_step(title: "Install") { "Get an app" }
    end
    assert_selector "li div[role='group']", text: "Get an app"
  end

  def test_side_layout_puts_the_steps_beside_the_panels
    render_inline(UI::Stepper.new(orientation: :vertical, layout: :side)) do |stepper|
      stepper.with_step(title: "Format") { "Pick one" }
    end
    assert_selector "div[data-slot='stepper'] > div.grid > nav + div", text: "Pick one"
  end

  def test_completion_shows_once_every_step_is_done
    render_inline(UI::Stepper.new(current: 2)) do |stepper|
      stepper.with_step(title: "Only") { "Fields" }
      stepper.with_completion { "All done" }
    end
    assert_text "All done"
    refute_selector "p.\\@md\\/stepper\\:hidden"
  end

  def test_completion_is_hidden_until_then
    render_inline(UI::Stepper.new) do |stepper|
      stepper.with_step(title: "Only") { "Fields" }
      stepper.with_completion { "All done" }
    end
    assert_selector "div[hidden]", text: "All done", visible: :all
  end

  def test_block_comes_after_the_panels
    render_inline(UI::Stepper.new) do |stepper|
      stepper.with_step(title: "Only") { "Fields" }
      "Buttons"
    end
    assert_match(/Fields.*Buttons/m, page.native.to_html)
  end

  def test_class_and_attributes_pass_through
    render_steps(class: "max-w-xl", id: "signup", data: { turbo: false })
    root = page.find("div#signup[data-turbo='false']")
    assert_includes root[:class], "max-w-xl"
    assert_selector "li span[id='signup-step-1']"
  end

  def render_panels(**opts)
    render_inline(UI::Stepper.new(current: 2, **opts)) do |stepper|
      stepper.with_step(title: "Account") { "Account fields" }
      stepper.with_step(title: "Plan") { "Plan fields" }
      stepper.with_step(title: "Payment") { "Card fields" }
    end
  end

  def test_with_panels_a_done_step_is_a_button_back_to_it
    render_panels
    controller = "ui--stepper"
    back = page.find("li[data-status='complete'] button[type='button']")
    assert_equal "Account", back.text
    refute back.disabled?
    assert_equal "#{controller}#select", back["data-action"]
    assert_equal "click->#{controller}#select", page.find("li[data-status='complete'] span[aria-hidden]", match: :first)["data-action"]
  end

  def test_steps_not_done_yet_are_disabled_buttons
    render_panels
    assert_selector "li[data-status='current'] button[disabled]", text: "Plan"
    assert_selector "li[data-status='upcoming'] button[disabled]", text: "Payment"
  end

  def test_navigable_false_keeps_titles_plain
    render_panels(navigable: false)
    refute_selector "li button"
  end

  def test_without_panels_titles_are_plain
    render_steps(current: 2)
    refute_selector "li button"
  end
end

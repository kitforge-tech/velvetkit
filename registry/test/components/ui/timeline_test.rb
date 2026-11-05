# frozen_string_literal: true

require "test_helper"

class UI::TimelineTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_items(titles = %w[Placed Paid Shipped], **opts)
    render_inline(UI::Timeline.new(**opts)) { |timeline| titles.each { |title| timeline.with_item(title: title) } }
  end

  def render_item(variant: :default, **opts, &block)
    render_inline(UI::Timeline.new(variant: variant)) { |timeline| timeline.with_item(title: "Paid", **opts, &block) }
  end

  def test_renders_a_labelled_ordered_list_in_the_order_given
    render_items
    assert_selector "ol[data-slot='timeline'][aria-label='Timeline'] > li[data-slot='timeline-item']", count: 3
    assert_equal %w[Placed Paid Shipped], page.all("li > div > div > span:first-child").map { |s| s.text.split(",").first }
  end

  def test_label_names_the_list
    render_items(label: "Order history")
    assert_selector "ol[aria-label='Order history']"
  end

  def test_status_defaults_to_complete
    render_item
    assert_selector "li[data-status='complete']"
  end

  def test_each_status_is_marked_and_read_out
    { complete: "Completed", current: "In progress", upcoming: "Not started", error: "Failed" }.each do |status, words|
      render_item(status: status)
      assert_selector "li[data-status='#{status}'] .sr-only", text: words
    end
  end

  def test_unknown_status_falls_back_to_complete
    render_item(status: :nonsense)
    assert_selector "li[data-status='complete']"
  end

  def test_only_the_current_item_has_aria_current
    render_item(status: :current)
    assert_selector "li[aria-current='step']"
    render_item(status: :complete)
    assert_no_selector "li[aria-current]"
  end

  def test_status_marks
    render_item(status: :complete)
    assert_selector "svg[data-icon='check']"
    render_item(status: :error)
    assert_selector "svg[data-icon='x']"
    render_item(status: :upcoming)
    assert_no_selector "svg"
  end

  def test_icon_replaces_the_status_mark
    render_item(icon: "credit-card")
    assert_selector "svg[data-icon='credit-card']"
    assert_no_selector "svg[data-icon='check']"
  end

  def test_dot_variant_draws_no_icons
    render_item(variant: :dot, icon: "credit-card")
    assert_selector "ol[data-variant='dot']"
    assert_no_selector "svg"
  end

  def marker_classes = page.all("li > span[aria-hidden]:not(.absolute)").map { |marker| marker[:class] }

  def render_colored(*items)
    render_inline(UI::Timeline.new(variant: :colored)) do |timeline|
      items.each { |opts| timeline.with_item(title: "Step", **opts) }
    end
  end

  def test_colored_variant_gives_each_circle_its_own_colour_and_wraps_round
    count = UI::Timeline::Item::COLORS.size
    render_colored(*Array.new(count + 1) { {} })
    fills = marker_classes.map { |classes| classes[/bg-\w+-600/] }
    assert_equal count, fills.first(count).uniq.size
    assert_equal fills.first, fills.last
  end

  def test_color_chooses_the_colour_and_an_unknown_one_keeps_its_turn
    render_colored({ color: :rose }, { color: :nonsense })
    assert_includes marker_classes.first, "bg-rose-600"
    assert_includes marker_classes.last, "bg-emerald-600"
  end

  def test_colored_current_item_wears_a_ring_in_its_colour
    render_colored({ color: :teal, status: :current })
    assert_includes marker_classes.first, "ring-teal-600/20"
  end

  def test_colored_keeps_the_look_of_errors_and_upcoming_items
    render_colored({ color: :teal, status: :error }, { color: :teal, status: :upcoming })
    assert_includes marker_classes.first, "bg-destructive"
    assert_includes marker_classes.last, "bg-muted"
  end

  def test_color_is_ignored_outside_the_colored_variant
    render_item(color: :rose)
    assert_includes marker_classes.first, "bg-primary"
  end

  def test_colored_connectors_stay_neutral
    render_colored({}, {})
    assert_selector "li > span.absolute.bg-border", count: 1
  end

  def test_unknown_variant_falls_back_to_default
    render_items(variant: :nonsense)
    assert_selector "ol[data-variant='default']"
  end

  def test_connector_on_every_item_but_the_last
    render_items
    assert_selector "li", count: 3
    assert_selector "li > span.absolute", count: 2
    assert_no_selector "li:last-child > span.absolute"
  end

  def test_time_renders_a_time_element_with_a_machine_readable_date
    at = Time.utc(2026, 11, 5, 14, 30)
    render_item(time: at)
    assert_selector "time[datetime='#{at.iso8601}']", text: I18n.l(at, format: :long)
  end

  def test_date_renders_without_a_time_of_day
    render_item(time: Date.new(2026, 11, 5))
    assert_selector "time[datetime='2026-11-05']", text: I18n.l(Date.new(2026, 11, 5), format: :long)
  end

  def test_time_label_changes_the_words_but_keeps_the_date
    at = Time.utc(2026, 11, 5, 14, 30)
    render_item(time: at, time_label: "2 hours ago")
    assert_selector "time[datetime='#{at.iso8601}']", text: "2 hours ago"
  end

  def test_string_time_is_shown_as_it_is_with_no_time_element
    render_item(time: "Expected Friday")
    assert_text "Expected Friday"
    assert_no_selector "time"
  end

  def test_no_time_renders_nothing_for_it
    render_item
    assert_no_selector "time"
  end

  def test_description_and_block
    render_item(description: "Card ending 4242") { "Refund issued" }
    assert_selector "p", text: "Card ending 4242"
    assert_text "Refund issued"
  end

  def test_title_is_escaped
    render_inline(UI::Timeline.new) { |t| t.with_item(title: "<b>Paid</b>") }
    assert_no_selector "b"
    assert_text "<b>Paid</b>"
  end

  def test_class_and_html_attributes_pass_through
    render_inline(UI::Timeline.new(class: "mt-4", id: "history", data: { foo: "bar" })) do |timeline|
      timeline.with_item(title: "Paid", class: "opacity-50", id: "paid")
    end
    assert_selector "ol#history.mt-4[data-foo='bar'][data-slot='timeline']"
    assert_selector "li#paid.opacity-50[data-slot='timeline-item']"
  end
end

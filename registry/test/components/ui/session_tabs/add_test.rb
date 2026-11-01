# frozen_string_literal: true

require "test_helper"

class UI::SessionTabs::AddTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_with_add(size: :default, **opts)
    render_inline(UI::SessionTabs.new(size: size)) do |tabs|
      tabs.with_tab(value: "a", active: true) { "Alpha" }
      tabs.with_add(**opts)
    end
  end

  def test_without_url_is_an_event_button
    render_with_add
    button = page.find("button[aria-label='New tab']")
    assert_equal "button", button[:type]
    assert_includes button["data-action"], "click->ui--session-tabs#add"
    assert_no_selector "form"
  end

  def test_with_url_posts_a_form
    render_with_add(url: "/tabs")
    form = page.find("form[action='/tabs']")
    assert_equal "post", form[:method]
    assert form.has_selector?("button[aria-label='New tab'][data-action~='click->ui--session-tabs#add']")
  end

  def test_custom_label
    render_with_add(label: "New order")
    assert_selector "button[aria-label='New order'][title='New order']"
  end

  def test_touch_size
    render_with_add(size: :touch)
    assert_includes page.find("button[aria-label='New tab']")[:class], "size-8"
  end

  def test_default_size_is_compact
    render_with_add
    assert_includes page.find("button[aria-label='New tab']")[:class], "size-7"
  end

  def test_keeps_user_action
    render_with_add(data: { action: "click->analytics#track" })
    action = page.find("button[aria-label='New tab']")["data-action"]
    assert_includes action, "click->analytics#track"
    assert_includes action, "click->ui--session-tabs#add"
  end
end

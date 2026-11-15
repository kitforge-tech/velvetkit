# frozen_string_literal: true

require "test_helper"

class UI::SelectionBarTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_starts_hidden_and_watches_the_list_it_names
    render_inline(UI::SelectionBar.new(for: "customers"))
    bar = page.find("[data-slot=selection-bar][role=region][aria-label='Selection']", visible: :all)
    assert bar[:hidden]
    assert_equal "ui--selection-bar", bar[:"data-controller"]
    assert_equal "customers", bar[:"data-ui--selection-bar-for-value"]
    assert_equal "%{count} selected", bar[:"data-ui--selection-bar-other-value"]
    assert_includes bar[:class], "sticky"
  end

  def test_clear_button_and_live_count
    render_inline(UI::SelectionBar.new(for: "photos"))
    assert_selector "button[aria-label='Clear selection'][data-action='ui--selection-bar#clear'] svg[data-icon='x']", visible: :all
    assert_selector "p[aria-live=polite][data-ui--selection-bar-target=count]", visible: :all
  end

  def test_actions_and_placement
    render_inline(UI::SelectionBar.new(for: "photos", placement: :floating, label: "Chosen photos", class: "bottom-8")) do |bar|
      bar.with_action { "<button>Archive</button>".html_safe }
      bar.with_action { "<button>Delete</button>".html_safe }
    end
    bar = page.find("[data-slot=selection-bar]", visible: :all)
    assert_equal "Chosen photos", bar[:"aria-label"]
    assert_equal "floating", bar[:"data-placement"]
    assert_includes bar[:class], "rounded-full"
    assert_includes bar[:class], "bottom-8"
    assert_equal %w[Archive Delete], bar.all("div button", visible: :all).map { |b| b.text(:all) }
  end

  def test_checkbox_for_any_list
    render_inline(UI::SelectionBar.checkbox(:item, name: "ids[]", value: "cat-2", form: "selection", label: "Select Curled up", class: "rounded-full"))
    box = page.find("input[type=checkbox]")
    assert_equal "item", box[:"data-selection"]
    assert_equal "selection", box[:form]
    assert_equal "Select Curled up", box[:"aria-label"]
    assert_includes box[:class], "rounded-full"
  end
end

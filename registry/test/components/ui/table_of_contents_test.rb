# frozen_string_literal: true

require "test_helper"

class UI::TableOfContentsTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_toc(**opts)
    render_inline(UI::TableOfContents.new(**opts)) do |toc|
      toc.with_item(href: "#process", text: "Contribution process") do |item|
        item.with_item(href: "#issue", text: "Create an issue")
        item.with_item(href: "#merge", text: "Merge your changes")
      end
      toc.with_item(href: "#resources", text: "Resources")
    end
  end

  # Structure

  def test_renders_nav_landmark_with_default_label
    render_toc
    assert_selector "nav[aria-label='On this page']"
  end

  def test_custom_label
    render_toc(label: "Sections")
    assert_selector "nav[aria-label='Sections']"
  end

  def test_title_labels_the_nav
    render_toc(title: "On this page", id: "toc")
    assert_selector "nav#toc[aria-labelledby='toc-title']:not([aria-label])"
    assert_selector "p#toc-title", text: "On this page"
  end

  def test_renders_top_level_links
    render_toc
    assert_selector "nav > div > ul > li > a[href='#process']", text: "Contribution process"
    assert_selector "nav > div > ul > li > a[href='#resources']", text: "Resources"
  end

  def test_nested_items_render_in_a_nested_list
    render_toc
    assert_selector "li > ul > li > a[href='#issue']", text: "Create an issue"
    assert_selector "li > ul > li > a[href='#merge']"
  end

  def test_nested_links_are_tighter_than_top_level
    render_toc
    assert_includes page.find("a[href='#process']")[:class].split, "py-1.5"
    assert_includes page.find("a[href='#issue']")[:class].split, "py-1"
  end

  def test_leaf_items_have_no_nested_list
    render_toc
    assert_no_selector "a[href='#resources'] + ul"
  end

  # Controller wiring

  def test_root_carries_controller_and_values
    render_toc(offset: 120, container: "#main")
    nav = page.find("nav[data-controller~='ui--table-of-contents']")
    assert_equal "120", nav["data-ui--table-of-contents-offset-value"]
    assert_equal "#main", nav["data-ui--table-of-contents-container-value"]
  end

  def test_container_value_omitted_by_default
    render_toc
    nav = page.find("nav")
    assert_nil nav["data-ui--table-of-contents-container-value"]
  end

  def test_links_are_targets_with_click_action
    render_toc
    links = page.all("a[data-ui--table-of-contents-target='link']")
    assert_equal 4, links.size
    links.each do |link|
      assert_equal "click->ui--table-of-contents#select", link["data-action"]
      assert_equal "inactive", link["data-state"]
    end
  end

  def test_rail_and_indicator_targets
    render_toc
    assert_selector "[data-ui--table-of-contents-target='rail'] > [data-ui--table-of-contents-target='indicator'][aria-hidden='true']", visible: :all
  end

  def test_no_link_is_current_before_the_controller_runs
    render_toc
    assert_no_selector "a[aria-current]"
  end

  # Attributes

  def test_root_has_auto_generated_id
    render_toc
    assert page.find("nav")[:id].start_with?("ui-toc-")
  end

  def test_user_class_merge
    render_toc(class: "sticky top-20")
    classes = page.find("nav")[:class].split
    assert_includes classes, "sticky"
    assert_includes classes, "text-sm"
  end

  def test_html_attrs_passthrough_keeps_controller
    render_toc(data: { test_id: "toc" })
    assert_selector "nav[data-test-id='toc'][data-controller~='ui--table-of-contents']"
  end
end

# frozen_string_literal: true

require "test_helper"

class UI::TableOfContents::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_list_item_with_link
    render_inline(UI::TableOfContents::Item.new(href: "#usage", text: "Usage"))
    assert_selector "li > a[href='#usage']", text: "Usage"
  end

  def test_user_class_merge
    render_inline(UI::TableOfContents::Item.new(href: "#usage", text: "Usage", class: "italic"))
    classes = page.find("a")[:class].split
    assert_includes classes, "italic"
    assert_includes classes, "rounded-md"
  end

  def test_html_attrs_and_data_merge_onto_link
    render_inline(UI::TableOfContents::Item.new(href: "#usage", text: "Usage", title: "Usage", data: { turbo: false }))
    link = page.find("a")
    assert_equal "Usage", link[:title]
    assert_equal "false", link["data-turbo"]
    assert_equal "link", link["data-ui--table-of-contents-target"]
  end

  def test_children_nest_deeper
    render_inline(UI::TableOfContents::Item.new(href: "#a", text: "A")) do |item|
      item.with_item(href: "#b", text: "B") do |child|
        child.with_item(href: "#c", text: "C")
      end
    end
    assert_selector "li > ul > li > ul > li > a[href='#c']"
    assert_includes page.find("a[href='#c']")[:class].split, "py-1"
  end
end

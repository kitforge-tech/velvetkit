# frozen_string_literal: true

require "test_helper"

class UI::EmptyStateTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_title_description_and_icon
    render_inline(UI::EmptyState.new(icon: "inbox", title: "No messages", description: "You're all caught up."))
    assert_selector "[data-slot='empty-state'] h3", text: "No messages"
    assert_selector "[data-slot='empty-state'] p", text: "You're all caught up."
    assert_selector "[data-slot='empty-state'] svg[data-icon='inbox']", visible: :all
  end

  def test_block_is_the_actions_row
    render_inline(UI::EmptyState.new(title: "No projects")) { "<button>Create project</button>".html_safe }
    assert_selector "[data-slot='empty-state'] div.flex-wrap button", text: "Create project"
  end

  def test_no_actions_row_without_a_block
    render_inline(UI::EmptyState.new(title: "No projects"))
    assert_no_selector "div.flex-wrap"
  end

  def test_no_icon_box_without_an_icon
    render_inline(UI::EmptyState.new(title: "No projects"))
    assert_no_selector "svg", visible: :all
    assert_no_selector "div.bg-muted"
  end

  def test_media_replaces_the_icon
    render_inline(UI::EmptyState.new(icon: "inbox", title: "No team")) do |empty|
      empty.with_media { "<img alt='Team' src='/team.png'>".html_safe }
    end
    assert_selector "img[alt='Team']"
    assert_no_selector "svg[data-icon='inbox']", visible: :all
  end

  def test_heading_level
    render_inline(UI::EmptyState.new(title: "Nothing here", heading_level: 2))
    assert_selector "h2", text: "Nothing here"
    assert_no_selector "h3"
  end

  def test_heading_level_is_kept_in_range
    render_inline(UI::EmptyState.new(title: "Nothing here", heading_level: 9))
    assert_selector "h6", text: "Nothing here"
  end

  def test_description_keeps_html
    render_inline(UI::EmptyState.new(description: "Read <a href='/docs'>the guide</a>.".html_safe))
    assert_selector "p a[href='/docs']", text: "the guide"
  end

  def test_description_escapes_plain_strings
    render_inline(UI::EmptyState.new(description: "<b>bold</b>"))
    assert_no_selector "p b"
    assert_selector "p", text: "<b>bold</b>"
  end

  def test_default_variant_has_no_border
    render_inline(UI::EmptyState.new(title: "x"))
    classes = page.find("[data-slot='empty-state']")[:class].split
    assert_includes classes, "text-center"
    refute_includes classes, "border-dashed"
  end

  def test_outline_variant
    render_inline(UI::EmptyState.new(title: "x", variant: :outline))
    classes = page.find("[data-slot='empty-state']")[:class].split
    assert_includes classes, "border"
    assert_includes classes, "border-dashed"
  end

  def test_user_class_merges
    render_inline(UI::EmptyState.new(title: "x", class: "p-2"))
    classes = page.find("[data-slot='empty-state']")[:class].split
    assert_includes classes, "p-2"
    refute_includes classes, "p-6"
  end

  def test_html_attrs_pass_through_and_keep_the_slot
    render_inline(UI::EmptyState.new(title: "x", id: "projects-empty", data: { test_id: "empty" }))
    assert_selector "#projects-empty[data-slot='empty-state'][data-test-id='empty']"
  end
end

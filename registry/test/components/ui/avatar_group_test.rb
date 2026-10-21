# frozen_string_literal: true

require "test_helper"

class UI::AvatarGroupTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_list_container
    render_inline(UI::AvatarGroup.new) do |group|
      group.with_avatar { "A" }
      group.with_avatar { "B" }
    end
    assert_selector "div[role='list']"
  end

  def test_avatars_have_listitem_role
    render_inline(UI::AvatarGroup.new) do |group|
      group.with_avatar { "A" }
    end
    assert_selector "[data-slot='avatar'][role='listitem']"
  end

  def test_renders_all_avatars
    render_inline(UI::AvatarGroup.new) do |group|
      group.with_avatar { "A" }
      group.with_avatar { "B" }
      group.with_avatar { "C" }
    end
    avatars = page.all("[data-slot='avatar']")
    assert_equal 3, avatars.size
  end

  def test_overflow_has_aria_label
    render_inline(UI::AvatarGroup.new(max: 2)) do |group|
      group.with_avatar { "A" }
      group.with_avatar { "B" }
      group.with_avatar { "C" }
      group.with_avatar { "D" }
    end
    overflow = page.find("span[aria-label]")
    assert_equal "2 more users", overflow["aria-label"]
  end

  def test_overflow_visible_count
    render_inline(UI::AvatarGroup.new(max: 2)) do |group|
      group.with_avatar { "A" }
      group.with_avatar { "B" }
      group.with_avatar { "C" }
      group.with_avatar { "D" }
    end
    avatars = page.all("[data-slot='avatar']")
    assert_equal 2, avatars.size
    assert_selector "span", text: "+2"
  end

  def test_no_overflow_when_within_max
    render_inline(UI::AvatarGroup.new(max: 5)) do |group|
      group.with_avatar { "A" }
      group.with_avatar { "B" }
    end
    refute_selector "span[aria-label]"
  end

  def test_user_class_merge
    render_inline(UI::AvatarGroup.new(class: "my-group")) do |group|
      group.with_avatar { "A" }
    end
    classes = page.find("div[role='list']")[:class].split
    assert_includes classes, "my-group"
  end

  def test_html_attrs_passthrough
    render_inline(UI::AvatarGroup.new(data: { test_id: "grp" })) do |group|
      group.with_avatar { "A" }
    end
    assert_selector "div[data-test-id='grp']"
  end
end

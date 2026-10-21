# frozen_string_literal: true

require "test_helper"

class UI::SidebarTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_sidebar(**opts)
    render_inline(UI::Sidebar.new(**opts)) do |sidebar|
      sidebar.with_sidebar_header { "Header" }
      sidebar.with_sidebar_content do |content|
        content.with_sidebar_group do |group|
          group.with_label("Applications")
          group.with_menu do |menu|
            menu.with_menu_item do |item|
              item.with_menu_button("#", active: true) { "Dashboard" }
            end
          end
        end
      end
    end
  end

  def test_renders_aside_with_sidebar_target
    render_sidebar
    aside = page.find("aside[data-ui--sidebar-target='sidebar']")
    assert_equal "expanded", aside[:"data-state"]
    assert_equal "none", aside[:"data-collapsible"]
  end

  def test_custom_id_preserved
    render_sidebar(id: "main-sidebar")
    assert_selector "aside#main-sidebar"
  end

  def test_user_class_merge
    render_sidebar(class: "custom-sidebar")
    classes = page.find("aside")[:class].split
    assert_includes classes, "custom-sidebar"
    assert_includes classes, "peer"
  end
end

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
    # Empty while open: the collapsed styles hang off "icon" and "offcanvas".
    assert_equal "", aside[:"data-collapsible"]
    assert_equal "icon", aside[:"data-collapsible-mode"]
  end

  def test_collapsed_says_how
    render_sidebar(collapsible: :offcanvas, state: :collapsed)
    aside = page.find("aside")
    assert_equal "collapsed", aside[:"data-state"]
    assert_equal "offcanvas", aside[:"data-collapsible"]
  end

  def test_a_sidebar_that_cannot_collapse_stays_open
    render_sidebar(collapsible: :none, state: :collapsed)
    assert_equal "expanded", page.find("aside")[:"data-state"]
  end

  def test_starts_as_the_reader_last_left_it
    vc_test_request.set_header("HTTP_COOKIE", "ui_sidebar_main_sidebar=collapsed")
    render_sidebar(id: "main-sidebar")
    aside = page.find("aside#main-sidebar")
    assert_equal "collapsed", aside[:"data-state"]
    assert_equal "ui_sidebar_main_sidebar", aside[:"data-cookie"]
  end

  def test_a_drawer_with_a_backdrop_on_phones
    render_sidebar
    assert_selector "[data-slot=sidebar-backdrop][data-action='click->ui--sidebar#close']", visible: :all
    container = page.find("[data-slot=sidebar-container]")
    assert_includes container[:class], "group-data-[mobile=open]:translate-x-0"
    assert_includes container[:class], "md:sticky"
    assert_includes container[:class], "md:max-h-full"
  end

  def test_sub_menu_opens_for_its_current_page
    render_inline(UI::Sidebar.new) do |sidebar|
      sidebar.with_sidebar_content do |content|
        content.with_sidebar_group do |group|
          group.with_menu do |menu|
            menu.with_menu_item do |item|
              item.with_menu_button("/albums", shape: :pill) { "Albums" }
              item.with_sub_menu(name: "Albums") do |sub|
                sub.with_item("/albums/1") { "Coast" }
                sub.with_item("/albums/2", active: true) { "Garden" }
              end
            end
            menu.with_menu_item do |item|
              item.with_menu_button("/places") { "Places" }
              item.with_sub_menu(name: "Places") { |sub| sub.with_item("/places/1") { "Lisbon" } }
            end
          end
        end
      end
    end

    toggles = page.all("button[data-action='ui--sidebar#toggleSub']")
    assert_equal %w[true false], toggles.map { |toggle| toggle[:"aria-expanded"] }
    assert_equal "Show the links under Albums", toggles.first[:"aria-label"]
    albums = page.find("ul##{toggles.first[:"aria-controls"]}")
    assert_selector "a[href='/albums/2'][aria-current=page]", text: "Garden"
    assert_nil albums[:hidden]
    assert page.find("ul##{toggles.last[:"aria-controls"]}", visible: :all)[:hidden]
    assert_selector "a[data-shape=pill]", text: "Albums"
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

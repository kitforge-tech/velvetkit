# frozen_string_literal: true

require "test_helper"

class UI::NavigationMenuTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_nav(**opts)
    render_inline(UI::NavigationMenu.new(**opts)) do |nav|
      nav.with_item(label: "Getting started") do |item|
        item.with_link(title: "Introduction", href: "/docs", description: "Re-usable components.")
        item.with_link(title: "Installation", href: "/docs/install")
      end
      nav.with_item(label: "Docs", href: "/docs")
    end
  end

  def test_is_a_labelled_nav_with_the_controller
    render_nav
    nav = page.find("nav[data-controller~='ui--navigation-menu']")
    assert_equal "Main", nav["aria-label"]
    assert nav[:id].start_with?("ui-navigation-menu-")
    assert_includes nav["data-action"], "focusout->ui--navigation-menu#focusOut"
    assert_includes nav["data-action"], "focusin->ui--navigation-menu#focusIn"
  end

  def test_custom_label_and_delays
    render_nav(label: "Product", open_delay: 0, close_delay: 500)
    nav = page.find("nav")
    assert_equal "Product", nav["aria-label"]
    assert_equal "0", nav["data-ui--navigation-menu-open-delay-value"]
    assert_equal "500", nav["data-ui--navigation-menu-close-delay-value"]
  end

  def test_item_with_links_is_a_disclosure_trigger
    render_nav
    trigger = page.find("button", text: "Getting started")
    assert_equal "false", trigger["aria-expanded"]
    panel = page.find("##{trigger['aria-controls']}", visible: :all)
    assert panel[:hidden]
    assert_equal "closed", panel["data-state"]
    assert_includes trigger["data-action"], "click->ui--navigation-menu#toggle"
    assert_includes trigger["data-action"], "pointerenter->ui--navigation-menu#hoverOpen"
    assert_includes trigger["data-ui--navigation-menu-target"].split, "trigger"
  end

  def test_it_is_not_an_aria_menu
    render_nav
    assert_no_selector "[role='menu'], [role='menuitem']", visible: :all
  end

  def test_trigger_has_a_rotating_chevron
    render_nav
    icon = page.find("button", text: "Getting started").find("[data-lucide='chevron-down']", visible: :all)
    assert_includes icon[:class], "group-aria-expanded/nav-item:rotate-180"
  end

  def test_item_without_panel_is_a_plain_link
    render_nav
    link = page.find("a", text: "Docs")
    assert_equal "/docs", link[:href]
    assert_nil link["aria-expanded"]
    assert_includes link["data-ui--navigation-menu-target"], "top"
  end

  def test_active_plain_link_is_current_page
    render_inline(UI::NavigationMenu.new) { |nav| nav.with_item(label: "Docs", href: "/docs", active: true) }
    assert_selector "a[aria-current='page']", text: "Docs"
  end

  def test_panel_links_have_title_and_description
    render_nav
    link = page.find("a[href='/docs']", text: "Introduction", visible: :all)
    assert link.has_text?(:all, "Re-usable components.")
    assert_equal "link", link["data-ui--navigation-menu-target"]
    assert_selector "a[href='/docs/install']", text: "Installation", visible: :all
  end

  def test_panel_link_icon_and_active
    render_inline(UI::NavigationMenu.new) do |nav|
      nav.with_item(label: "More") { |i| i.with_link(title: "Status", href: "/s", icon: "circle-check", active: true) }
    end
    link = page.find("a[href='/s']", visible: :all)
    assert link.has_selector?("[data-lucide='circle-check']", visible: :all)
    assert_includes link[:class], "items-center"
    assert_equal "page", link["aria-current"]
  end

  def test_two_columns
    render_inline(UI::NavigationMenu.new) do |nav|
      nav.with_item(label: "Components", columns: 2) { |i| i.with_link(title: "A", href: "/a") }
    end
    assert_selector "ul.sm\\:grid-cols-2", visible: :all
    assert_includes page.find("[data-ui--navigation-menu-target='panel']", visible: :all)[:class], "w-[36rem]"
  end

  def test_custom_panel_content
    render_inline(UI::NavigationMenu.new) do |nav|
      nav.with_item(label: "Company", panel_class: "w-96") { "<p class='promo'>We're hiring</p>".html_safe }
    end
    assert_selector "button", text: "Company"
    panel = page.find("[data-ui--navigation-menu-target='panel']", visible: :all)
    assert panel.has_selector?("p.promo", visible: :all)
    assert_includes panel[:class], "w-96"
  end

  def test_ids_are_unique_per_item
    render_inline(UI::NavigationMenu.new(id: "nav")) do |nav|
      nav.with_item(label: "One") { |i| i.with_link(title: "A", href: "/a") }
      nav.with_item(label: "Two") { |i| i.with_link(title: "B", href: "/b") }
    end
    assert_equal %w[nav-panel-1 nav-panel-2], page.all("button", visible: :all).map { _1["aria-controls"] }
  end

  def test_active_trigger_is_marked
    render_inline(UI::NavigationMenu.new) do |nav|
      nav.with_item(label: "Docs", active: true) { |i| i.with_link(title: "A", href: "/a") }
    end
    assert_selector "button[data-active]", text: "Docs"
  end

  def test_class_and_attrs_on_nav
    render_nav(class: "my-nav", data: { turbo_permanent: true })
    nav = page.find("nav")
    assert_includes nav[:class], "my-nav"
    assert_equal "true", nav["data-turbo-permanent"]
    assert_equal "ui--navigation-menu", nav["data-controller"]
  end
end

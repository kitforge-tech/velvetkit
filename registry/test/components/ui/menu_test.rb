# frozen_string_literal: true

require "test_helper"

class UI::MenuTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_menu
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Open Menu" }
      menu.with_content do |content|
        content.with_label("My Account")
        content.with_item("Profile")
        content.with_item("Settings")
        content.with_divider
        content.with_item("Logout", variant: :destructive)
      end
    end
  end

  def test_root_renders_trigger_and_content
    result = render_menu
    assert_text "Open Menu"
    assert_text "Profile"
    assert_text "Settings"
    assert_text "Logout"
  end

  def test_trigger_has_aria_attributes
    render_menu
    trigger = page.find("[data-ui--menu-target='trigger']")
    assert_equal "true", trigger[:"aria-haspopup"]
    assert_equal "false", trigger[:"aria-expanded"]
    assert trigger[:"aria-controls"].present?
    assert trigger[:"aria-controls"].start_with?("ui-menu-content-")
  end

  def test_trigger_has_toggle_action
    render_menu
    trigger = page.find("[data-ui--menu-target='trigger']")
    assert trigger[:"data-action"].include?("click->ui--menu#toggle")
    assert trigger[:"data-action"].include?("keydown->ui--menu#triggerKeydown")
  end

  def test_content_has_role_menu
    render_menu
    assert_selector "[role='menu']", visible: false
  end

  def test_content_has_vertical_orientation
    render_menu
    content = page.find("[role='menu']", visible: false)
    assert_equal "vertical", content[:"aria-orientation"]
  end

  def test_content_is_initially_hidden
    render_menu
    content = page.find("[role='menu']", visible: false)
    assert content[:hidden].present?
  end

  def test_default_side_is_bottom
    render_menu
    content = page.find("[role='menu']", visible: false)
    assert_equal "bottom", content[:"data-side"]
  end

  def test_default_align_is_start
    render_menu
    content = page.find("[role='menu']", visible: false)
    assert_equal "start", content[:"data-align"]
  end

  def test_custom_side
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content(side: :top) do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_id_preserved
    render_inline(UI::Menu.new(id: "my-menu")) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    assert_selector "#my-menu"
  end

  def test_user_class_merge
    render_inline(UI::Menu.new(class: "my-custom-class")) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    root = page.find("[data-controller='ui--menu']")
    classes = root[:class].split
    assert_includes classes, "my-custom-class"
    assert_includes classes, "relative"
  end

  def test_html_attrs_passthrough
    render_inline(UI::Menu.new(data: { test_id: "menu-x" })) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    assert_selector "[data-controller='ui--menu'][data-test-id='menu-x']"
  end

  def test_content_with_collected_items
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content do |content|
        content.with_label("Account")
        content.with_item("Profile", href: "/profile")
        content.with_item("Settings")
        content.with_divider
        content.with_item("Logout", variant: :destructive)
      end
    end

    assert_selector "[role='menu']", visible: false
    assert_text "Account"
    assert_selector "a[href='/profile']", text: "Profile", visible: false
    assert_selector "[role='menuitem']", text: "Settings", visible: false
    assert_selector "[role='separator']", visible: false
    assert_selector "[role='menuitem']", text: "Logout", visible: false
  end

  def test_item_with_block_content
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Open" }
      menu.with_content do |content|
        content.with_item do
          safe_join([ tag.div("Icon", class: "icon"), "Profile" ])
        end
      end
    end

    assert_text "Icon"
    assert_text "Profile"
  end
end

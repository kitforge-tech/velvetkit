# frozen_string_literal: true

require "test_helper"

class UI::Menu::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_content
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Menu content")
      end
    end
    assert result.to_html.include?("Menu content")
  end

  def test_has_role_menu
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    assert_selector "[role='menu']", visible: false
  end

  def test_has_vertical_orientation
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "vertical", content[:"aria-orientation"]
  end

  def test_is_initially_hidden
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert content[:hidden].present?
  end

  def test_has_data_target
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "content", content[:"data-ui--menu-target"]
  end

  def test_default_side_bottom
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "bottom", content[:"data-side"]
  end

  def test_custom_side
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content(side: :top) do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "top", content[:"data-side"]
  end

  def test_custom_align
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content(align: :end) do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_equal "end", content[:"data-align"]
  end

  def test_has_animation_classes
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert content[:class].include?("animate-in")
    assert content[:class].include?("fade-in-0")
  end

  def test_has_min_width
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert content[:class].include?("min-w-[8rem]")
  end

  def test_has_popover_styling
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert content[:class].include?("bg-popover")
    assert content[:class].include?("text-popover-foreground")
    assert content[:class].include?("rounded-md")
    assert content[:class].include?("shadow-md")
  end

  def test_custom_class_merge
    render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content(class: "custom-content") do |content|
        content.with_item("Item")
      end
    end
    content = page.find("[role='menu']", visible: false)
    assert_includes content[:class].split, "custom-content"
  end

  def test_collects_items
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_label("Account")
        content.with_item("Profile")
        content.with_item("Settings")
        content.with_divider
        content.with_item("Logout")
      end
    end

    assert result.to_html.include?("Account")
    assert result.to_html.include?("Profile")
    assert result.to_html.include?("Settings")
    assert result.to_html.include?("Logout")
  end

  def test_renders_separator
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item 1")
        content.with_divider
        content.with_item("Item 2")
      end
    end

    assert_selector "[role='separator']", visible: false
  end

  def test_renders_label
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_label("My Label")
        content.with_item("Item")
      end
    end

    assert_text "My Label"
    assert_selector "div", text: "My Label", visible: false
  end

  def test_item_as_link
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Profile", href: "/profile")
      end
    end

    assert_selector "a[href='/profile']", text: "Profile", visible: false
  end

  def test_item_with_variant
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Delete", variant: :destructive)
      end
    end

    item = page.find("[role='menuitem']", text: "Delete", visible: false)
    assert_includes item[:class].split, "text-destructive"
  end

  def test_item_with_inset
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Item", inset: true)
      end
    end

    item = page.find("[role='menuitem']", text: "Item", visible: false)
    assert_includes item[:class].split, "pl-8"
  end

  def test_disabled_item
    result = render_inline(UI::Menu.new) do |menu|
      menu.with_trigger { "Trigger" }
      menu.with_content do |content|
        content.with_item("Disabled", disabled: true)
      end
    end

    item = page.find("[role='menuitem']", text: "Disabled", visible: false)
    assert_equal "true", item[:"data-disabled"]
  end
end

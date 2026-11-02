# frozen_string_literal: true

require "test_helper"

class UI::SessionTabsTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_tabs(**root_opts, &block)
    render_inline(UI::SessionTabs.new(**root_opts)) do |tabs|
      if block
        block.call(tabs)
      else
        tabs.with_tab(value: "a", active: true, rename: true, close: true) { "Alpha" }
        tabs.with_tab(value: "b", rename: true, close: true) { "Beta" }
      end
    end
  end

  def test_root_carries_controller_and_values
    render_tabs(min_tabs: 2, return_focus: "#search", rename_param: "view[name]")
    root = page.find("[data-controller~='ui--session-tabs']")
    assert_equal "2", root["data-ui--session-tabs-min-tabs-value"]
    assert_equal "#search", root["data-ui--session-tabs-return-focus-value"]
    assert_equal "view[name]", root["data-ui--session-tabs-rename-param-value"]
    assert_equal "Tab name", root["data-ui--session-tabs-rename-label-value"]
    assert root[:id].start_with?("ui-session-tabs-")
  end

  def test_tablist_has_accessible_name
    render_tabs(label: "Documents")
    assert_selector "[role='tablist'][aria-label='Documents']"
  end

  def test_tablist_label_defaults_to_translation
    render_tabs
    assert_selector "[role='tablist'][aria-label='Open tabs']"
  end

  def test_tab_without_href_is_a_button
    render_tabs
    assert_selector "button[role='tab'][type='button']", text: "Alpha"
  end

  def test_tab_with_href_is_a_link
    render_tabs do |t|
      t.with_tab(value: "a", href: "/docs/a", active: true) { "Alpha" }
    end
    link = page.find("a[role='tab']")
    assert_equal "/docs/a", link[:href]
    assert_equal "page", link["aria-current"]
  end

  def test_active_state_and_roving_tabindex
    render_tabs
    active = page.find("[role='tab']", text: "Alpha")
    inactive = page.find("[role='tab']", text: "Beta")
    assert_equal "true", active["aria-selected"]
    assert_equal "0", active[:tabindex]
    assert_equal "false", inactive["aria-selected"]
    assert_equal "-1", inactive[:tabindex]
    assert_selector "[data-ui--session-tabs-target='tab'][data-value='a'][data-state='active']"
    assert_selector "[data-ui--session-tabs-target='tab'][data-value='b'][data-state='inactive']"
  end

  def test_wrapper_is_presentation
    render_tabs
    assert_selector "[role='presentation'][data-ui--session-tabs-target='tab']", count: 2
  end

  def test_tab_html_attrs_go_on_the_tab_element
    render_tabs do |t|
      t.with_tab(value: "a", href: "/a", data: { turbo_frame: "pane" }) { "Alpha" }
    end
    tab = page.find("a[role='tab']")
    assert_equal "pane", tab["data-turbo-frame"]
    assert_includes tab["data-action"], "click->ui--session-tabs#select"
  end

  def test_meta_slot
    render_tabs do |t|
      t.with_tab(value: "a") do |tab|
        tab.with_meta { "3 items" }
        "Alpha"
      end
    end
    assert_selector "[role='tab'] span", text: "3 items"
  end

  def test_no_menu_without_actions
    render_tabs do |t|
      t.with_tab(value: "a") { "Alpha" }
    end
    assert_no_selector "[data-controller~='ui--menu']"
  end

  def test_menu_items_follow_enabled_actions
    render_tabs do |t|
      t.with_tab(value: "a", rename: true) { "Alpha" }
      t.with_tab(value: "b") { "Beta" }
    end
    assert_selector "[role='menuitem']", text: "Rename", visible: :all
    assert_no_selector "[role='menuitem']", text: "Duplicate", visible: :all
    assert_no_selector "[role='menuitem']", text: "Close", visible: :all
  end

  def test_menu_trigger_is_labelled_by_tab
    render_tabs
    trigger = page.find("[data-ui--session-tabs-target='menuTrigger']", match: :first)
    assert_equal "Tab options", trigger["aria-label"]
    label_id = page.find("[data-ui--session-tabs-target='label']", text: "Alpha")[:id]
    assert_equal label_id, trigger["aria-describedby"]
  end

  def test_action_urls_and_flags
    render_tabs do |t|
      t.with_tab(value: "a", rename: "/a/rename", duplicate: "/a/dup", move: true, close: "/a",
                 close_confirm: "Discard?") { "Alpha" }
      t.with_tab(value: "b") { "Beta" }
    end
    tab = page.find("[data-value='a']")
    assert_equal "/a/rename", tab["data-rename-url"]
    assert_equal "/a/dup", tab["data-duplicate-url"]
    assert_equal "/a", tab["data-close-url"]
    assert_nil tab["data-move-url"]
    assert_equal "true", tab["data-move-enabled"]
    assert_equal "Discard?", tab["data-close-confirm"]
  end

  def test_menu_actions_are_wired
    render_tabs do |t|
      t.with_tab(value: "a", rename: true, duplicate: true, move: true, close: true) { "Alpha" }
      t.with_tab(value: "b") { "Beta" }
    end
    %w[rename duplicate moveLeft moveRight close].each do |action|
      assert_selector "[role='menuitem'][data-action='click->ui--session-tabs##{action}']", visible: :all
    end
  end

  def test_move_left_hidden_on_first_and_move_right_on_last
    render_tabs do |t|
      t.with_tab(value: "a", move: true) { "Alpha" }
      t.with_tab(value: "b", move: true) { "Beta" }
    end
    first = page.find("[data-value='a']")
    last  = page.find("[data-value='b']")
    assert first.has_selector?("[data-move='left'][hidden][data-disabled]", visible: :all)
    assert first.has_selector?("[data-move='right']:not([hidden])", visible: :all)
    assert last.has_selector?("[data-move='right'][hidden][data-disabled]", visible: :all)
    assert last.has_selector?("[data-move='left']:not([hidden])", visible: :all)
  end

  def test_fixed_tab_is_never_passed
    render_tabs do |t|
      t.with_tab(value: "default") { "Default" }
      t.with_tab(value: "a", move: true) { "Alpha" }
      t.with_tab(value: "b", move: true) { "Beta" }
    end
    alpha = page.find("[data-value='a']")
    assert alpha.has_selector?("[data-move='left'][hidden]", visible: :all)
    assert_nil page.find("[data-value='default']")["data-move-enabled"]
  end

  def test_movable_tab_gets_a_drag_handle
    render_tabs do |t|
      t.with_tab(value: "a", move: true) { "Alpha" }
    end
    handle = page.find("[data-ui--session-tabs-target='handle']", visible: :all)
    assert_equal "pointerdown->ui--session-tabs#dragStart", handle["data-action"]
    assert_equal "true", handle["aria-hidden"]
    assert_includes handle[:class], "touch-none"
    assert handle.has_selector?("[data-icon='grip-vertical']", visible: :all)
  end

  def test_controls_reveal_on_hover_and_slide_in
    render_tabs do |t|
      t.with_tab(value: "a", move: true, rename: true) { "Alpha" }
    end
    grip = page.find("[data-ui--session-tabs-target='handle'] [data-icon]", visible: :all)[:class]
    menu = page.find("[data-ui--session-tabs-target='menuTrigger']")[:class]
    dots = page.find("[data-ui--session-tabs-target='menuTrigger'] [data-icon]", visible: :all)[:class]
    [ grip, menu ].each do |classes|
      assert_includes classes, "opacity-0"
      assert_includes classes, "group-hover/tab:opacity-100"
      assert_includes classes, "group-focus-within/tab:opacity-100"
      assert_includes classes, "[@media(hover:none)]:opacity-100"
    end
    assert_includes grip, "-translate-x-2"
    assert_includes dots, "translate-x-2"
    assert_includes dots, "group-hover/tab:translate-x-0"
    assert_includes page.find("[data-value='a']")[:class], "hover:bg-primary/5"
  end

  def test_fixed_tab_has_no_handle
    render_tabs do |t|
      t.with_tab(value: "a", rename: true) { "Alpha" }
    end
    assert_no_selector "[data-ui--session-tabs-target='handle']", visible: :all
  end

  def test_tab_body_is_draggable_but_not_natively
    render_tabs do |t|
      t.with_tab(value: "a", href: "/a", move: true) { "Alpha" }
    end
    tab = page.find("a[role='tab']")
    assert_includes tab["data-action"], "pointerdown->ui--session-tabs#pressStart"
    assert_equal "false", tab[:draggable]
  end

  def test_menu_trigger_is_compact
    render_tabs
    assert_includes page.find("[data-ui--session-tabs-target='menuTrigger']", match: :first)[:class], "size-6"
  end

  def test_close_hidden_at_min_tabs
    render_tabs do |t|
      t.with_tab(value: "a", close: true) { "Alpha" }
    end
    assert_selector "[role='menuitem'][data-close-part][hidden][data-disabled]", visible: :all
  end

  def test_close_available_above_min_tabs
    render_tabs
    assert_selector "[role='menuitem'][data-close-part]:not([hidden])", visible: :all, count: 2
  end

  def test_close_is_destructive_and_divided
    render_tabs
    item = page.find("[role='menuitem'][data-close-part]", match: :first, visible: :all)
    assert_includes item[:class], "text-destructive"
    assert_selector "[role='separator'][data-close-part]", visible: :all, count: 2
  end

  def test_extra_menu_items
    render_tabs do |t|
      t.with_tab(value: "a", close: true) do |tab|
        tab.with_menu_item("Pin", data: { action: "click->pins#toggle" })
        "Alpha"
      end
      t.with_tab(value: "b") { "Beta" }
    end
    assert_selector "[role='menuitem'][data-action='click->pins#toggle']", text: "Pin", visible: :all
  end

  def test_confirm_dialog_is_rendered_once
    render_tabs
    assert_selector "[data-ui--session-tabs-target='dialog'] dialog", count: 1, visible: :all
    assert_selector "[data-ui--session-tabs-target='confirmMessage']", visible: :all
    assert_selector "button[data-action='click->ui--session-tabs#confirmClose']", text: "Close tab", visible: :all
  end

  def test_touch_size
    render_tabs(size: :touch)
    assert_includes page.find("[data-value='a']")[:class], "h-11"
  end

  def test_default_size
    render_tabs
    assert_includes page.find("[data-value='a']")[:class], "h-9"
  end

  def test_unknown_size_falls_back
    render_tabs(size: :huge)
    assert_includes page.find("[data-value='a']")[:class], "h-9"
  end

  def test_user_class_and_attrs_on_root
    render_tabs(class: "my-tabs", id: "doc-tabs", data: { turbo_permanent: true })
    root = page.find("#doc-tabs")
    assert_includes root[:class], "my-tabs"
    assert_equal "ui--session-tabs", root["data-controller"]
    assert_equal "true", root["data-turbo-permanent"]
  end

  def test_values_with_spaces_get_safe_ids
    render_tabs do |t|
      t.with_tab(value: "Saved view 1") { "One" }
    end
    assert page.find("[role='tab']")[:id].end_with?("-tab-saved-view-1")
  end
end

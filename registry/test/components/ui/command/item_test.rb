# frozen_string_literal: true

require "test_helper"

class UI::Command::ItemTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_an_option_carrying_what_the_controller_needs
    render_inline(UI::Command::Item.new(label: "Settings", href: "/settings", id: "s"))
    assert_selector "div#s[role='option'][aria-selected='false'][data-ui--command-target='item'][data-label='Settings'][data-href='/settings'][data-value='/settings']", text: "Settings"
  end

  def test_value_defaults_to_href_then_label
    render_inline(UI::Command::Item.new(label: "New invoice", value: "new-invoice"))
    assert_selector "[data-value='new-invoice']"
    assert_no_selector "[data-href]"
    render_inline(UI::Command::Item.new(label: "Log out"))
    assert_selector "[data-value='Log out']"
  end

  def test_icon_description_and_keywords
    render_inline(UI::Command::Item.new(label: "Invoices", icon: "receipt", description: "All bills, paid and unpaid", keywords: %w[bills money]))
    assert_selector "span[aria-hidden='true'] svg[data-icon='receipt']"
    assert_selector "span.text-xs.text-muted-foreground", text: "All bills, paid and unpaid"
    assert_selector "[data-keywords='bills money']"
  end

  def test_a_shortcut_is_shown_and_bound_only_when_asked
    render_inline(UI::Command::Item.new(label: "Settings", shortcut: "mod+,", id: "s"))
    assert_selector "[role='option'] [data-slot='kbd'].ms-auto"
    assert_no_selector "[data-ui--kbd-keys-value]"
    render_inline(UI::Command::Item.new(label: "Settings", shortcut: "mod+,", bind: true, id: "s"))
    assert_selector "[data-ui--kbd-keys-value='mod+,'][data-ui--kbd-target-value='#s']"
  end

  def test_disabled_items_say_so_and_do_not_bind
    render_inline(UI::Command::Item.new(label: "Export", shortcut: "mod+e", bind: true, disabled: true))
    assert_selector "[role='option'][aria-disabled='true']"
    assert_no_selector "[data-ui--kbd-keys-value]"
  end

  def test_a_block_replaces_how_it_looks_but_not_its_label
    render_inline(UI::Command::Item.new(label: "Ada Lovelace")) { "<strong>Ada</strong> Lovelace".html_safe }
    assert_selector "[role='option'][data-label='Ada Lovelace'] strong", text: "Ada"
  end
end

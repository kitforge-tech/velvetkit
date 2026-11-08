# frozen_string_literal: true

require "test_helper"

class UI::CommandTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_command(**opts)
    render_inline(UI::Command.new(id: "cmd", **opts)) do |command|
      command.with_trigger if opts[:dialog]
      command.with_group(heading: "Pages") do |group|
        group.with_item(label: "Dashboard", href: "/dashboard", icon: "house")
        group.with_item(label: "Settings", href: "/settings", shortcut: "mod+,")
      end
      command.with_group(heading: "Actions") do |group|
        group.with_item(label: "New invoice", value: "new-invoice", keywords: %w[create bill])
      end
    end
  end

  def test_a_combobox_over_a_listbox
    render_command
    assert_selector "[data-controller='ui--command'] input#cmd-input[role='combobox'][aria-controls='cmd-list'][aria-expanded='true'][aria-autocomplete='list']"
    assert_selector "#cmd-list[role='listbox'][aria-label='Command menu']"
    assert_selector "input[placeholder='Type a command or search…'][aria-label='Command menu']"
  end

  def test_groups_and_items_are_listed_in_order
    render_command
    assert_equal %w[Pages Actions], page.all("[role='group'] > div:first-child").map(&:text)
    assert_equal [ "Dashboard", "Settings", "New invoice" ], page.all("[role='option']").map { |o| o["data-label"] }
    assert_selector "[role='group'][aria-labelledby]", count: 2
  end

  def test_on_a_page_it_is_the_panel_with_no_dialog_or_footer
    render_command
    assert_no_selector "dialog"
    assert_no_selector "button[data-action='ui--command#open']"
    assert_selector "[data-ui--command-dialog-value='false'][data-ui--command-shortcut-value='']"
    assert_no_text "to move"
  end

  def test_as_a_dialog_it_has_a_trigger_a_shortcut_and_a_footer
    render_command(dialog: true)
    assert_selector "dialog[aria-label='Command menu'][data-ui--command-target='dialog'] [data-ui--command-target='panel']"
    assert_selector "button[data-action='ui--command#open'][aria-haspopup='dialog']", text: "Search…"
    assert_selector "button[data-action='ui--command#open'] [data-slot='kbd']"
    assert_selector "[data-ui--command-dialog-value='true'][data-ui--command-shortcut-value='mod+k']"
    assert_text "to move"
    assert_text "to close"
  end

  def test_the_shortcut_can_change_or_go
    render_command(dialog: true, shortcut: "/")
    assert_selector "[data-ui--command-shortcut-value='/']"
    render_command(dialog: true, shortcut: nil)
    assert_selector "[data-ui--command-shortcut-value='']"
    assert_no_selector "button[data-action='ui--command#open'] [data-slot='kbd']"
  end

  def test_a_trigger_with_its_own_label_or_content
    render_inline(UI::Command.new(dialog: true)) { |c| c.with_trigger(label: "Jump to…", class: "w-64") }
    assert_selector "button.w-64", text: "Jump to…"
    render_inline(UI::Command.new(dialog: true)) { |c| c.with_trigger(variant: :ghost) { "Open" } }
    assert_selector "button[data-action='ui--command#open']", exact_text: "Open"
  end

  def test_searching_the_server_is_set_up_only_with_a_url
    render_command
    assert_no_selector "[data-ui--command-url-value]"
    render_command(url: "/search", param: "term", results_heading: "Customers")
    assert_selector "[data-ui--command-url-value='/search'][data-ui--command-param-value='term'][data-ui--command-results-heading-value='Customers']"
    assert_selector "template[data-ui--command-target='template']", visible: :all
  end

  def test_messages_for_the_controller
    render_command
    assert_selector "[data-ui--command-empty-value='No results found.'][data-ui--command-searching-value='Searching…']"
    assert_selector "[data-ui--command-target='empty'][hidden]", visible: :all
    assert_selector "[data-ui--command-target='status'][role='status'][hidden]", visible: :all
  end

  def test_custom_placeholder_label_and_attributes
    render_inline(UI::Command.new(placeholder: "Find a page", label: "Site search", class: "max-w-md", data: { testid: "c" }))
    assert_selector "[data-controller='ui--command'].max-w-md[data-testid='c'] input[placeholder='Find a page'][aria-label='Site search']"
  end
end

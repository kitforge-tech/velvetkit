# frozen_string_literal: true

require "test_helper"

class UI::TableTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_roster
    render_inline(UI::Table.new) do |table|
      table.with_head do |head|
        head.with_column { "Name" }
        head.with_column(align: :end) { "Roll" }
      end
      table.with_row do |row|
        row.with_cell { "Aditi Rao" }
        row.with_cell(align: :end) { "12" }
      end
      table.with_row do |row|
        row.with_cell { "Arjun Nair" }
        row.with_cell(align: :end) { "13" }
      end
    end
  end

  def test_renders_a_semantic_table
    render_roster
    assert_selector "table thead tr th", count: 2
    assert_selector "table tbody tr", count: 2
    assert_selector "table tbody tr:first-child td", text: "Aditi Rao"
  end

  # Screen readers announce a header cell differently from a data cell, so the
  # distinction has to be real markup rather than styling.
  def test_header_cells_are_th_with_a_scope
    render_roster
    assert_equal "col", page.find("thead th", text: "Name")[:scope]
  end

  # A long roster scrolls sideways on a phone rather than breaking the page.
  def test_wraps_the_table_in_a_horizontal_scroll_container
    render_roster
    assert_includes page.find("div", match: :first)[:class].split, "overflow-x-auto"
  end

  def test_alignment_applies_to_matching_head_and_body_cells
    render_roster
    assert_includes page.find("thead th", text: "Roll")[:class].split, "text-right"
    assert_includes page.find("tbody td", text: "12")[:class].split, "text-right"
  end

  def test_caption_is_rendered_when_given
    render_inline(UI::Table.new(caption: "Grade 8 B")) do |table|
      table.with_row { |row| row.with_cell { "x" } }
    end
    assert_selector "table caption", text: "Grade 8 B"
  end

  def test_no_caption_element_without_one
    render_roster
    assert_no_selector "caption"
  end

  # An empty roster should say so rather than render a bare header.
  def test_empty_state_replaces_the_body_when_there_are_no_rows
    render_inline(UI::Table.new) do |table|
      table.with_head { |head| head.with_column { "Name" } }
      table.with_empty_state { "No students enrolled yet" }
    end
    assert_text "No students enrolled yet"
    assert_no_selector "tbody tr td", text: "Aditi"
  end

  def test_empty_state_is_ignored_once_rows_exist
    render_inline(UI::Table.new) do |table|
      table.with_head { |head| head.with_column { "Name" } }
      table.with_empty_state { "No students enrolled yet" }
      table.with_row { |row| row.with_cell { "Aditi Rao" } }
    end
    assert_no_text "No students enrolled yet"
    assert_selector "tbody td", text: "Aditi Rao"
  end

  def test_rows_can_be_marked_selected
    render_inline(UI::Table.new) do |table|
      table.with_row(selected: true) { |row| row.with_cell { "Aditi" } }
    end
    assert_equal "true", page.find("tbody tr")[:"aria-selected"]
  end

  def test_user_class_overrides_default_via_tailwind_merge
    render_inline(UI::Table.new(class: "text-base")) do |table|
      table.with_row { |row| row.with_cell { "x" } }
    end
    classes = page.find("table")[:class].split
    assert_includes classes, "text-base"
    refute_includes classes, "text-sm"
  end

  def test_html_attrs_pass_through
    render_inline(UI::Table.new(id: "roster", data: { test_id: "t" })) do |table|
      table.with_row { |row| row.with_cell { "x" } }
    end
    assert_selector "table#roster[data-test-id='t']"
  end
end

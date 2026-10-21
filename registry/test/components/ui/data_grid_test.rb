# frozen_string_literal: true

require "test_helper"

class UI::DataGridTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  URL = "/customers.json"

  def render_grid(**options)
    render_inline(UI::DataGrid.new(url: URL, **options)) do |grid|
      grid.column(:id, "ID", width: 90, type: :number)
      grid.column(:name, "Name")
      grid.column(:owner, "Owner")
      grid.column(:notes, "Notes", sortable: false, filterable: false)
    end
  end

  def grid = page.find("div[data-controller='ui--data-grid']")
  def columns = JSON.parse(grid["data-ui--data-grid-columns-value"])

  def test_declares_the_stimulus_controller
    render_grid
    assert_selector "div[data-controller='ui--data-grid']"
  end

  # Rows are never embedded: the grid fetches each page from this URL, sending
  # the sort and filter it wants applied.
  def test_points_at_the_url_it_fetches_pages_from
    render_grid
    assert_equal URL, grid["data-ui--data-grid-url-value"]
    assert_nil grid["data-ui--data-grid-rows-value"]
  end

  def test_columns_carry_the_field_header_type_and_width
    render_grid
    assert_equal %w[id name owner notes], columns.map { |c| c["field"] }
    assert_equal [ "ID", "Name", "Owner", "Notes" ], columns.map { |c| c["headerName"] }
    assert_equal 90, columns.first["width"]
    assert_equal "number", columns.first["type"]
  end

  # Only the declared width is sent, so AG Grid keeps sizing the rest itself.
  def test_omits_width_when_not_given
    render_grid
    refute columns.last.key?("width")
  end

  # A column the server has no SQL expression for must not offer the control:
  # a sort arrow that does nothing is worse than no sort arrow.
  def test_columns_declare_whether_the_server_can_sort_or_filter_them
    render_grid
    assert columns.first["sortable"]
    assert columns.first["filterable"]
    refute columns.last["sortable"]
    refute columns.last["filterable"]
  end

  def test_empty_message_reaches_the_grid
    render_grid(empty_message: "No customers yet")
    assert_equal "No customers yet", grid["data-ui--data-grid-empty-message-value"]
  end

  def test_page_size_defaults_to_a_screenful_and_can_be_set
    render_grid
    assert_equal "15", grid["data-ui--data-grid-page-size-value"]
    render_grid(page_size: 50)
    assert_equal "50", grid["data-ui--data-grid-page-size-value"]
  end

  # The height is reserved before the grid paints, so the page does not jump
  # when its chunk arrives.
  def test_reserves_height_for_a_full_page_of_rows
    render_grid(page_size: 10)
    assert_equal "height: 448px", grid[:style]
  end

  def test_user_class_merges
    render_grid(class: "mt-8")
    assert_includes grid[:class].split, "mt-8"
  end

  def test_html_attrs_pass_through
    render_grid(id: "customers")
    assert_selector "div#customers"
  end
end

# frozen_string_literal: true

# UI::DataGrid — a sortable, filterable, server-paged table backed by AG Grid.
#
# The grid holds one page at a time and asks the server for the next, sending
# the sort and filter it wants applied. Paging, sorting and filtering all
# happen in Postgres — see the GridQuery concern for the other half.
#
# Columns are declared in Ruby so the headers, their widths and which of them
# the server will accept a sort or filter for are decided in one place.
#
# AG Grid is ~365 KB gzipped, so the Stimulus controller fetches it at connect
# time: a page without a grid never downloads it.
#
# Usage:
#   <%= render(UI::DataGrid.new(url: section_path(@section, format: :json)) do |grid|
#         grid.column(:roll_number, t(".roll"), width: 110, type: :number)
#         grid.column(:name, t(".name"))
#         grid.column(:guardian, t(".guardian"), sortable: false, filterable: false)
#       end) %>
class UI::DataGrid < UI::Base
  Column = Struct.new(:field, :header, :width, :type, :sortable, :filterable,
                      keyword_init: true)

  def initialize(url:, page_size: 15, empty_message: nil, class: nil, **html_attrs)
    @url = url
    @page_size = page_size
    @empty_message = empty_message
    @columns = []
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  # sortable/filterable default to true, and are turned off for a column the
  # server has no SQL expression for — a value read through an association,
  # or one translated for display. Offering the control and then ignoring it
  # would be worse than not offering it.
  def column(field, header, width: nil, type: :text, sortable: true, filterable: true)
    @columns << Column.new(field: field.to_s, header: header, width: width, type: type,
                           sortable: sortable, filterable: filterable)
    self
  end

  def before_render
    content # declares the columns
  end

  # Rows navigate on click when the server sends a path with them, so the
  # cursor has to say so.
  def classes = cn("[&_.ag-row]:cursor-pointer", @user_class)

  def grid_options
    {
      controller: "ui--data-grid",
      "ui--data-grid-url-value": @url,
      "ui--data-grid-columns-value": column_specs.to_json,
      "ui--data-grid-page-size-value": @page_size,
      "ui--data-grid-empty-message-value": @empty_message || t("ui.data_grid.empty"),
      # Propshaft digests the filename, so the URL has to come from Ruby.
      "ui--data-grid-module-url-value": helpers.asset_path("ag_grid.js")
    }
  end

  # Reserves the grid's final height before its chunk arrives, so the page does
  # not jump once it paints.
  def reserved_height = "#{HEADER_HEIGHT + (ROW_HEIGHT * @page_size) + FOOTER_HEIGHT}px"

  HEADER_HEIGHT = 36
  ROW_HEIGHT = 36
  FOOTER_HEIGHT = 52

  private

  def column_specs
    @columns.map do |column|
      spec = { field: column.field, headerName: column.header, type: column.type,
               sortable: column.sortable, filterable: column.filterable }
      spec[:width] = column.width if column.width
      spec
    end
  end
end

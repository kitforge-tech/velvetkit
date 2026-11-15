# frozen_string_literal: true

# UI::Table — a data table.
#
# Lists get long and phones are narrow, so the table is always wrapped in a
# horizontal scroll container rather than allowed to break the page layout.
#
# Usage:
#   <%= render(UI::Table.new(caption: "Invoices")) do |table| %>
#     <% table.with_head do |head| %>
#       <% head.with_column { "Customer" } %>
#       <% head.with_column(align: :end) { "Amount" } %>
#     <% end %>
#     <% @invoices.each do |invoice| %>
#       <% table.with_row do |row| %>
#         <% row.with_cell { invoice.customer.name } %>
#         <% row.with_cell(align: :end) { number_to_currency(invoice.amount) } %>
#       <% end %>
#     <% end %>
#     <% table.with_empty_state { "No invoices yet" } %>
#   <% end %>
#
# A column sorts on the server: give it the link that sorts by it, and which
# way it's sorted now, and the header becomes that link with an arrow, read
# out by screen readers as sorted (aria-sort).
#
#   <% head.with_column(sort_href: invoices_path(sort: "amount", dir: "desc"), sorted: :asc) { "Amount" } %>
#
# `selection: "ids[]"` adds a checkbox to each row, named that, with the
# value each row gives (`with_row(value: invoice.id, label: invoice.number)`),
# and a box in the header for all of them (made with UI::SelectionBar.checkbox). `form:` is the id of the form the
# boxes post with, when the table isn't inside it. A `UI::SelectionBar` for
# the table counts what's chosen, shows the actions for it and handles
# select-all and Shift-click.
#
# `sticky_header: true` keeps the header in sight while the rows scroll under
# it, inside `max_height:` ("32rem"); the table scrolls in its own box then.
class UI::Table < UI::Base
  renders_one :head, ->(**args) { UI::Table::Head.new(selection: @selection, sticky: @sticky_header, form: @form, **args) }
  renders_many :rows, ->(**args) { UI::Table::Row.new(selection: @selection, form: @form, **args) }
  # Shown only when there are no rows, so an empty table reads as empty
  # rather than as a header with nothing under it.
  renders_one :empty_state

  def initialize(caption: nil, selection: nil, form: nil, sticky_header: false, max_height: nil, class: nil, **html_attrs)
    @caption    = caption
    @selection  = selection
    @form       = form
    @sticky_header = sticky_header
    @max_height = max_height
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :caption

  def classes = cn("w-full caption-bottom text-sm", @user_class)

  def empty? = rows.none?

  def show_empty_state? = empty? && empty_state?

  # Spans the full width so the message centres under the header.
  def column_count = (head? ? head.columns.size : 1) + (@selection ? 1 : 0)

  def wrapper_attrs
    { class: cn("relative w-full overflow-x-auto rounded-md border border-border", { "overflow-y-auto" => @max_height }),
      style: ("max-height: #{@max_height}" if @max_height), data: { slot: "table" } }
  end
end

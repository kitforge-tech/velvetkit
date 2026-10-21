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
class UI::Table < UI::Base
  renders_one :head, UI::Table::Head
  renders_many :rows, UI::Table::Row
  # Shown only when there are no rows, so an empty table reads as empty
  # rather than as a header with nothing under it.
  renders_one :empty_state

  def initialize(caption: nil, class: nil, **html_attrs)
    @caption    = caption
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :caption

  def classes = cn("w-full caption-bottom text-sm", @user_class)

  def empty? = rows.none?

  def show_empty_state? = empty? && empty_state?

  # Spans the full width so the message centres under the header.
  def column_count = head? ? head.columns.size : 1
end

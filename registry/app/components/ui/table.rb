# frozen_string_literal: true

# UI::Table — a data table.
#
# Rosters are long and phones are narrow, so the table is always wrapped in a
# horizontal scroll container rather than allowed to break the page layout.
#
# Usage:
#   <%= render(UI::Table.new(caption: "Grade 8 B")) do |table| %>
#     <% table.with_head do |head| %>
#       <% head.with_column { "Name" } %>
#       <% head.with_column(align: :end) { "Roll" } %>
#     <% end %>
#     <% @enrollments.each do |enrollment| %>
#       <% table.with_row do |row| %>
#         <% row.with_cell { enrollment.person.display_name } %>
#         <% row.with_cell(align: :end) { enrollment.roll_number } %>
#       <% end %>
#     <% end %>
#     <% table.with_empty_state { "No students enrolled yet" } %>
#   <% end %>
class UI::Table < UI::Base
  renders_one :head, UI::Table::Head
  renders_many :rows, UI::Table::Row
  # Shown only when there are no rows, so an empty roster reads as empty
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

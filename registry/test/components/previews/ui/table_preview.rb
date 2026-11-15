# frozen_string_literal: true

class UI::TablePreview < ViewComponent::Preview
  # @label Customers
  def customers; render_with_template; end

  # @label Empty
  def empty; render_with_template; end

  # @label With Caption And Selection
  def with_caption; render_with_template; end

  # @label Sortable Columns
  def sortable; render_with_template; end

  # @label Rows to Select, With a Selection Bar
  def selectable; render_with_template; end

  # @label Sticky Header
  def sticky_header; render_with_template; end
end

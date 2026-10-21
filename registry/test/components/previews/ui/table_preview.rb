# frozen_string_literal: true

class UI::TablePreview < ViewComponent::Preview
  # @label Customers
  def customers; render_with_template; end

  # @label Empty
  def empty; render_with_template; end

  # @label With Caption And Selection
  def with_caption; render_with_template; end
end

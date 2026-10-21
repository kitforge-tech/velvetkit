# frozen_string_literal: true

class UI::Breadcrumb::AutoEllipsis < UI::Base
  def initialize(items:, size: :sm)
    @items = items
    @size = size
  end

  def size_text_class
    UI::Breadcrumb::SIZES[@size]
  end
end

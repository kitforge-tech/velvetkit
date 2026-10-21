# frozen_string_literal: true

class UI::PaginationPreview < ViewComponent::Preview
  # @label Playground
  # @param count number
  # @param page number
  # @param limit number
  def playground(count: 240, page: 1, limit: 25)
    render(UI::Pagination.new(pagy: Pagy::Offset.new(count: count.to_i, page: page.to_i,
                                                     limit: limit.to_i)))
  end

  # @label States
  def states; render_with_template; end
end

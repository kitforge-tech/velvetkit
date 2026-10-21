# frozen_string_literal: true

class UI::DataGridPreview < ViewComponent::Preview
  # The grid fetches its rows from the server, so a preview needs a real class
  # endpoint to point at, so here it shows the markup and the reserved height.
  # velvetkit.com's Data grid page has a live one.
  #
  # @label Playground
  # @param page_size number
  def playground(page_size: 15)
    render(UI::DataGrid.new(url: "/customers.json", page_size: page_size.to_i)) do |grid|
      grid.column(:id, "ID", width: 90, type: :number)
      grid.column(:name, "Name")
      grid.column(:plan, "Plan")
      grid.column(:owner, "Owner", sortable: false, filterable: false)
    end
  end
end

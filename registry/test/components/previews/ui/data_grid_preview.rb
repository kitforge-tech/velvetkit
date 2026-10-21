# frozen_string_literal: true

class UI::DataGridPreview < ViewComponent::Preview
  # The grid fetches its rows from the server, so a preview needs a real class
  # list to point at. Lookbook has no tenant, so this shows the markup and the
  # reserved height rather than a painted grid — see a section page for that.
  #
  # @label Playground
  # @param page_size number
  def playground(page_size: 15)
    render(UI::DataGrid.new(url: "/sections/1.json", page_size: page_size.to_i)) do |grid|
      grid.column(:roll_number, "Roll no.", width: 110, type: :number)
      grid.column(:name, "Name")
      grid.column(:admission_number, "Admission no.")
      grid.column(:guardian, "Parent", sortable: false, filterable: false)
    end
  end
end

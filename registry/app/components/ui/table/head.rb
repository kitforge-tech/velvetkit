# frozen_string_literal: true

# The header row of a UI::Table.
class UI::Table::Head < UI::Base
  renders_many :columns, ->(**args) { UI::Table::Column.new(sticky: @sticky, **args) }

  def initialize(selection: nil, sticky: false, form: nil, class: nil, **html_attrs)
    @selection  = selection
    @sticky     = sticky
    @form       = form
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def selection? = @selection.present?

  def select_all_box
    UI::SelectionBar.checkbox(:all, label: t("ui.table.select_all", default: "Select all rows"), form: nil)
  end

  def selection_cell_classes
    cn("h-10 w-px ps-3 pe-1 align-middle", { "sticky top-0 z-10 bg-muted" => @sticky })
  end

  def classes = cn("border-b border-border bg-muted/50", @user_class)
end
